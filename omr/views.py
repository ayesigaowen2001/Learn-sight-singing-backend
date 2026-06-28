from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import ScoreUpload
from .serializers import ScoreUploadSerializer
from .tasks import process_omr_task

class ScoreUploadViewSet(viewsets.ModelViewSet):
    queryset = ScoreUpload.objects.all()
    serializer_class = ScoreUploadSerializer
    http_method_names = ['get', 'post', 'head', 'options']

    def create(self, request, *args, **kwargs):
        file = request.FILES.get('file')
        if not file:
            return Response({'error': 'No file provided'}, status=400)
        allowed = ['.pdf','.png','.jpg','.jpeg','.tiff','.tif','.bmp']
        ext = '.' + file.name.split('.')[-1].lower()
        if ext not in allowed:
            return Response({'error': f'Unsupported. Allowed: {allowed}'}, status=400)
        upload = ScoreUpload.objects.create(original_file=file, original_filename=file.name)
        process_omr_task.delay(str(upload.id))
        return Response(self.get_serializer(upload).data, status=201)

    @action(detail=True, methods=['get'])
    def musicxml(self, request, pk=None):
        upload = get_object_or_404(ScoreUpload, pk=pk)
        if upload.status != ScoreUpload.Status.COMPLETED:
            return Response({'error': f'Not ready: {upload.status}'}, status=409)
        if not upload.musicxml_file:
            return Response({'error': 'No MusicXML'}, status=404)
        return Response({
            'url': self.get_serializer(upload).get_musicxml_url(upload),
            'filename': f'{upload.title or "score"}.musicxml',
        })
