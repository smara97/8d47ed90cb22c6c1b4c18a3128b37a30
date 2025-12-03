import { useAuth } from "@/_core/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useLocation } from "wouter";
import { Video, Plus, List, Info } from "lucide-react";
import { getLoginUrl } from "@/const";

export default function Home() {
  const [, navigate] = useLocation();

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900">
      {/* Hero Section */}
      <div className="container py-16 px-4">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center justify-center p-3 bg-blue-100 dark:bg-blue-900/30 rounded-full mb-6">
            <Video className="h-8 w-8 text-blue-600 dark:text-blue-400" />
          </div>
          <h1 className="text-5xl font-bold text-foreground mb-4">
            Camera Stream Manager
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            Manage and monitor your camera streams in one centralized platform. 
            Add RTSP streams or upload video files with ease.
          </p>
          
          <div className="flex gap-4 justify-center">
            <Button size="lg" onClick={() => navigate("/add-stream")}>
              <Plus className="mr-2 h-5 w-5" />
              Add New Stream
            </Button>
            <Button size="lg" variant="outline" onClick={() => navigate("/streams")}>
              <List className="mr-2 h-5 w-5" />
              View All Streams
            </Button>
          </div>
        </div>

        {/* Features Section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          <Card>
            <CardHeader>
              <div className="h-12 w-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center mb-4">
                <Plus className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
              <CardTitle>Add Streams</CardTitle>
              <CardDescription>
                Easily add camera streams using RTSP URLs or by uploading video files directly
              </CardDescription>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <div className="h-12 w-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center mb-4">
                <Video className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
              <CardTitle>Manage Cameras</CardTitle>
              <CardDescription>
                Organize your cameras with unique IDs and descriptions for easy identification
              </CardDescription>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <div className="h-12 w-12 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center mb-4">
                <List className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
              <CardTitle>View All Streams</CardTitle>
              <CardDescription>
                Access all your camera streams in one place with detailed information and quick links
              </CardDescription>
            </CardHeader>
          </Card>
        </div>

        {/* Info Section */}
        <Card className="max-w-3xl mx-auto mt-12">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Info className="h-5 w-5 text-blue-600" />
              <CardTitle>How It Works</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">
                1
              </div>
              <div>
                <h4 className="font-semibold mb-1">Add Your Camera</h4>
                <p className="text-muted-foreground">
                  Provide a unique camera ID and optional description to identify your stream
                </p>
              </div>
            </div>
            
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">
                2
              </div>
              <div>
                <h4 className="font-semibold mb-1">Choose Stream Type</h4>
                <p className="text-muted-foreground">
                  Select between RTSP URL for live streams or upload a video file for recorded footage
                </p>
              </div>
            </div>
            
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">
                3
              </div>
              <div>
                <h4 className="font-semibold mb-1">Manage & Monitor</h4>
                <p className="text-muted-foreground">
                  View all your streams in the dashboard and access them anytime
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
