from rest_framework import serializers
from .models import ScoreUpload

class ScoreUploadSerializer(serializers.ModelSerializer):
    musicxml_url = serializers.SerializerMethodField()
    class Meta:
        model = ScoreUpload
        fields = ['id','original_filename','status','musicxml_url','error_message','title','voices_detected','created_at','updated_at']
        read_only_fields = ['status','musicxml_url','error_message','title','voices_detected','created_at','updated_at']
    def get_musicxml_url(self, obj):
        if obj.musicxml_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.musicxml_file.url)
            return obj.musicxml_file.url
        return None
