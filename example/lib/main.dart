import 'package:flutter/material.dart';
import 'controller/app_controller.dart';
import 'intent/app_intent.dart';
import 'models/app_state.dart';
import 'services/video_service.dart';
import 'widgets/video_grid_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Video Thumbnail Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(VideoService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Video Thumbnail Demo'),
      ),
      body: StreamBuilder<AppState>(
        stream: _controller.stateStream,
        initialData: _controller.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data!;

          return Column(
            children: [
              if (state.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            _controller.handleIntent(ClearErrorIntent()),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: state.videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет видео',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите + чтобы добавить видео',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 16 / 9,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: state.videos.length,
                        itemBuilder: (context, index) {
                          final video = state.videos[index];
                          return VideoGridItem(
                            video: video,
                            onRemove: () => _controller.handleIntent(
                              RemoveVideoIntent(video.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<AppState>(
        stream: _controller.stateStream,
        initialData: _controller.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data!;
          return FloatingActionButton(
            onPressed: state.isPickingVideo
                ? null
                : () => _controller.handleIntent(PickVideoIntent()),
            child: state.isPickingVideo
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
