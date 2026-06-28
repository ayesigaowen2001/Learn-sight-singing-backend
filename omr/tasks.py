import os, shutil, subprocess, tempfile
from pathlib import Path
from celery import shared_task
from django.core.files import File
from .models import ScoreUpload

@shared_task(bind=True, max_retries=2, default_retry_delay=30)
def process_omr_task(self, upload_id: str):
    try:
        upload = ScoreUpload.objects.get(id=upload_id)
    except ScoreUpload.DoesNotExist:
        return
    upload.status = ScoreUpload.Status.PROCESSING
    upload.save()

    input_path = upload.original_file.path
    input_ext = Path(input_path).suffix.lower()
    working_path = input_path

    if input_ext in ('.png','.jpg','.jpeg','.tiff','.tif','.bmp'):
        working_path = _image_to_pdf(input_path)

    output_dir = tempfile.mkdtemp(prefix='audiveris_')
    try:
        result = subprocess.run(
            ['audiveris', '-batch', '-export', '-output', output_dir, '--', working_path],
            capture_output=True, text=True, timeout=300)
        if result.returncode != 0:
            upload.status = ScoreUpload.Status.FAILED
            upload.error_message = result.stderr[:1000]
            upload.save()
            return

        mxl = list(Path(output_dir).rglob('*.mxl'))
        xml = list(Path(output_dir).rglob('*.xml')) if not mxl else []
        found = mxl[0] if mxl else (xml[0] if xml else None)

        if not found:
            upload.status = ScoreUpload.Status.FAILED
            upload.error_message = 'No MusicXML output produced'
            upload.save()
            return

        with open(found, 'rb') as f_in:
            upload.musicxml_file.save(
                f'{Path(upload.original_filename).stem}.musicxml', File(f_in))
        upload.status = ScoreUpload.Status.COMPLETED
        upload.save()
    except subprocess.TimeoutExpired:
        upload.status = ScoreUpload.Status.FAILED
        upload.error_message = 'Processing timed out (5 min)'
        upload.save()
    except Exception as e:
        upload.status = ScoreUpload.Status.FAILED
        upload.error_message = str(e)[:1000]
        upload.save()
    finally:
        shutil.rmtree(output_dir, ignore_errors=True)
        if working_path != input_path:
            try: os.remove(working_path)
            except OSError: pass

def _image_to_pdf(path: str) -> str:
    from PIL import Image
    img = Image.open(path)
    pdf = tempfile.mktemp(suffix='.pdf')
    img.convert('RGB').save(pdf, 'PDF')
    return pdf
