import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/snap_provider.dart';

class SnapScreen extends ConsumerStatefulWidget {
  const SnapScreen({super.key});

  @override
  ConsumerState<SnapScreen> createState() => _SnapScreenState();
}

class _SnapScreenState extends ConsumerState<SnapScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap'),
      ),
      body: Column(
        children: [
          if (_selectedImage != null) ...[
            Expanded(
              child: Image.file(_selectedImage!),
            ),
            // FutureProvider for processing status
            Consumer(
              builder: (context, ref, child) {
                final imagePath = _selectedImage?.path;
                if (imagePath == null) return const SizedBox.shrink();

                final snapAsync = ref.watch(snapProcessingProvider(imagePath));
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: snapAsync.isLoading ? null : () {
                          ref.invalidate(snapProcessingProvider(imagePath));
                        },
                        child: snapAsync.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Process Snap'),
                      ),
                    ),
                    snapAsync.when(
                      data: (result) => Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Processing Complete!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text('Vector Sync: ${result.vectorSyncStatus}'),
                              const SizedBox(height: 16),
                              Text(
                                'Extracted Items:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              ...result.result['extracted_items'].map<Widget>((item) {
                                return Card(
                                  child: ListTile(
                                    title: Text(item['original_text'] ?? ''),
                                    subtitle: Text('Type: ${item['type']}'),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      loading: () => const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing...'),
                            ],
                          ),
                        ),
                      ),
                      error: (error, stack) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(snapProcessingProvider(imagePath));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 64),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera),
                      label: const Text('Take Photo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

