import { useState } from "react";
import { useLocation } from "wouter";
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";
import { Loader2, Upload, Link as LinkIcon } from "lucide-react";
// Storage will be imported dynamically when needed

export default function AddStream() {
  const [, navigate] = useLocation();
  const [cameraId, setCameraId] = useState("");
  const [cameraDescription, setCameraDescription] = useState("");
  const [streamType, setStreamType] = useState<"rtsp" | "video">("rtsp");
  const [rtspUrl, setRtspUrl] = useState("");
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);

  const utils = trpc.useUtils();
  
  const uploadVideoMutation = trpc.cameraStream.uploadVideo.useMutation();
  
  const addStreamMutation = trpc.cameraStream.add.useMutation({
    onSuccess: () => {
      toast.success("Camera stream added successfully!");
      navigate("/streams");
    },
    onError: (error) => {
      toast.error(error.message || "Failed to add camera stream");
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!cameraId.trim()) {
      toast.error("Camera ID is required");
      return;
    }

    if (streamType === "rtsp" && !rtspUrl.trim()) {
      toast.error("RTSP URL is required");
      return;
    }

    if (streamType === "video" && !videoFile) {
      toast.error("Please select a video file");
      return;
    }

    try {
      setUploading(true);

      let videoData;
      if (streamType === "video" && videoFile) {
        // Convert file to base64 for upload
        const fileBuffer = await videoFile.arrayBuffer();
        const uint8Array = new Uint8Array(fileBuffer);
        const binaryString = Array.from(uint8Array)
          .map(byte => String.fromCharCode(byte))
          .join('');
        const base64Data = btoa(binaryString);
        
        // Upload via tRPC
        const uploadResult = await uploadVideoMutation.mutateAsync({
          fileName: videoFile.name,
          fileData: base64Data,
          contentType: videoFile.type || "video/mp4",
          cameraId,
        });
        
        videoData = uploadResult;
      }

      const result = await addStreamMutation.mutateAsync({
        cameraId,
        cameraDescription,
        streamType,
        rtspUrl: streamType === "rtsp" ? rtspUrl : undefined,
        videoFile: videoData,
      });
      
      toast.success(`Camera ${cameraId} added successfully!`);
      
      // Reset form
      setCameraId("");
      setCameraDescription("");
      setRtspUrl("");
      setVideoFile(null);
      
      // Navigate to streams page after a short delay
      setTimeout(() => {
        navigate("/streams");
      }, 1000);
    } catch (error: any) {
      console.error("Upload error:", error);
      const errorMessage = error?.message || "Failed to add camera stream";
      toast.error(errorMessage);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div className="container max-w-2xl">
        <Card>
          <CardHeader>
            <CardTitle className="text-2xl">Add Camera Stream</CardTitle>
            <CardDescription>
              Add a new camera stream by providing an RTSP URL or uploading a video file
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="cameraId">Camera ID *</Label>
                <Input
                  id="cameraId"
                  placeholder="e.g., CAM-001"
                  value={cameraId}
                  onChange={(e) => setCameraId(e.target.value)}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="cameraDescription">Camera Description</Label>
                <Textarea
                  id="cameraDescription"
                  placeholder="Optional description of the camera location or purpose"
                  value={cameraDescription}
                  onChange={(e) => setCameraDescription(e.target.value)}
                  rows={3}
                />
              </div>

              <div className="space-y-4">
                <Label>Stream Type *</Label>
                <RadioGroup
                  value={streamType}
                  onValueChange={(value) => setStreamType(value as "rtsp" | "video")}
                >
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="rtsp" id="rtsp" />
                    <Label htmlFor="rtsp" className="font-normal cursor-pointer flex items-center gap-2">
                      <LinkIcon className="h-4 w-4" />
                      RTSP URL
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="video" id="video" />
                    <Label htmlFor="video" className="font-normal cursor-pointer flex items-center gap-2">
                      <Upload className="h-4 w-4" />
                      Upload Video File
                    </Label>
                  </div>
                </RadioGroup>
              </div>

              {streamType === "rtsp" && (
                <div className="space-y-2">
                  <Label htmlFor="rtspUrl">RTSP URL *</Label>
                  <Input
                    id="rtspUrl"
                    type="url"
                    placeholder="rtsp://example.com:554/stream"
                    value={rtspUrl}
                    onChange={(e) => setRtspUrl(e.target.value)}
                    required
                  />
                </div>
              )}

              {streamType === "video" && (
                <div className="space-y-2">
                  <Label htmlFor="videoFile">Video File *</Label>
                  <Input
                    id="videoFile"
                    type="file"
                    accept="video/*"
                    onChange={(e) => setVideoFile(e.target.files?.[0] || null)}
                    required
                  />
                  {videoFile && (
                    <p className="text-sm text-muted-foreground">
                      Selected: {videoFile.name} ({(videoFile.size / 1024 / 1024).toFixed(2)} MB)
                    </p>
                  )}
                </div>
              )}

              <div className="flex gap-3 pt-4">
                <Button
                  type="submit"
                  disabled={addStreamMutation.isPending || uploading}
                  className="flex-1"
                >
                  {(addStreamMutation.isPending || uploading) && (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  )}
                  Add Stream
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate("/")}
                  disabled={addStreamMutation.isPending || uploading}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
