import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useLocation } from "wouter";
import { Video, Link as LinkIcon, Plus, Calendar, Play, Maximize2 } from "lucide-react";

export default function Streams() {
  const [, navigate] = useLocation();
  const { data: streams, isLoading } = trpc.cameraStream.list.useQuery();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
        <div className="container">
          <div className="flex justify-between items-center mb-8">
            <Skeleton className="h-10 w-48" />
            <Skeleton className="h-10 w-32" />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <Card key={i}>
                <CardHeader>
                  <Skeleton className="h-6 w-32 mb-2" />
                  <Skeleton className="h-4 w-48" />
                </CardHeader>
                <CardContent>
                  <Skeleton className="h-20 w-full" />
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div className="container">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-foreground">Camera Streams</h1>
            <p className="text-muted-foreground mt-1">
              View and manage all camera streams
            </p>
          </div>
          <Button onClick={() => navigate("/add-stream")}>
            <Plus className="mr-2 h-4 w-4" />
            Add Stream
          </Button>
        </div>

        {!streams || streams.length === 0 ? (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-16">
              <Video className="h-16 w-16 text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">No camera streams yet</h3>
              <p className="text-muted-foreground mb-6 text-center">
                Get started by adding your first camera stream
              </p>
              <Button onClick={() => navigate("/add-stream")}>
                <Plus className="mr-2 h-4 w-4" />
                Add Your First Stream
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {streams.map((stream) => (
              <Card key={stream.id} className="overflow-hidden hover:shadow-xl transition-all border-2 hover:border-blue-500">
                {/* Video Preview Section - Hikvision Style */}
                <div className="relative bg-black aspect-video flex items-center justify-center group">
                  {stream.streamType === "video" && stream.videoUrl ? (
                    <>
                      <video
                        className="w-full h-full object-cover"
                        src={stream.videoUrl}
                        autoPlay
                        muted
                        loop
                        playsInline
                        controls={false}
                        onLoadedMetadata={(e) => {
                          const video = e.currentTarget;
                          video.play().catch(err => console.log('Auto-play prevented:', err));
                        }}
                      />
                      <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                        <Button
                          size="sm"
                          variant="secondary"
                          className="gap-2 bg-white/90 hover:bg-white"
                          onClick={() => window.open(stream.videoUrl!, '_blank')}
                        >
                          <Maximize2 className="h-4 w-4" />
                          Fullscreen
                        </Button>
                      </div>
                    </>
                  ) : stream.streamType === "rtsp" && stream.rtspUrl ? (
                    <div className="flex flex-col items-center justify-center text-white/80 p-4">
                      <LinkIcon className="h-12 w-12 mb-3" />
                      <p className="text-xs font-semibold mb-1">RTSP Stream</p>
                      <p className="text-xs text-center text-white/60 break-all px-2">
                        {stream.rtspUrl}
                      </p>
                      <p className="text-xs text-white/40 mt-2">Use external player to view</p>
                    </div>
                  ) : (
                    <div className="flex flex-col items-center justify-center text-white/60">
                      <Video className="h-12 w-12 mb-2" />
                      <p className="text-xs">No Preview Available</p>
                    </div>
                  )}
                  
                  {/* Status Indicator - Hikvision Style */}
                  <div className="absolute top-2 left-2 flex items-center gap-2">
                    <div className="flex items-center gap-1 bg-green-500 text-white text-xs px-2 py-1 rounded">
                      <div className="w-2 h-2 bg-white rounded-full animate-pulse" />
                      ONLINE
                    </div>
                  </div>
                  
                  {/* Stream Type Badge */}
                  <div className="absolute top-2 right-2">
                    <Badge variant={stream.streamType === "rtsp" ? "default" : "secondary"} className="text-xs">
                      {stream.streamType.toUpperCase()}
                    </Badge>
                  </div>
                </div>

                {/* Camera Info Section */}
                <CardHeader className="pb-3">
                  <CardTitle className="text-base font-bold flex items-center gap-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full" />
                    {stream.cameraId}
                  </CardTitle>
                  <CardDescription className="text-xs line-clamp-2">
                    {stream.cameraDescription || "No description provided"}
                  </CardDescription>
                </CardHeader>

                <CardContent className="pt-0 space-y-2">
                  {/* Stream URL Display */}
                  {stream.streamType === "rtsp" && stream.rtspUrl && (
                    <div className="bg-slate-100 dark:bg-slate-800 rounded p-2">
                      <p className="text-xs text-muted-foreground mb-1 font-semibold">Stream URL:</p>
                      <p className="text-xs font-mono break-all text-slate-700 dark:text-slate-300">
                        {stream.rtspUrl}
                      </p>
                    </div>
                  )}

                  {/* Timestamp */}
                  <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t">
                    <div className="flex items-center gap-1">
                      <Calendar className="h-3 w-3" />
                      <span>{new Date(stream.createdAt).toLocaleDateString()}</span>
                    </div>
                    <span className="text-xs">
                      {new Date(stream.createdAt).toLocaleTimeString()}
                    </span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
