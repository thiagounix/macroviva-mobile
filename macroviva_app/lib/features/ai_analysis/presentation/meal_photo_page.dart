import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../application/meal_photo_analysis_providers.dart';
import 'meal_analysis_result_page.dart';

class MealPhotoPage extends ConsumerStatefulWidget {
  const MealPhotoPage({super.key});

  @override
  ConsumerState<MealPhotoPage> createState() => _MealPhotoPageState();
}

class _MealPhotoPageState extends ConsumerState<MealPhotoPage> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final analyzeState = ref.watch(analyzeMealPhotoControllerProvider);
    final isAnalyzing = analyzeState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisar foto'),
        leading: IconButton(
          onPressed: isAnalyzing ? null : () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Foto da refeição',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _PhotoPreview(photo: _selectedPhoto),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isAnalyzing
                            ? null
                            : () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeria'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isAnalyzing
                            ? null
                            : () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Câmera'),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isAnalyzing ? null : _analyzePhoto,
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(isAnalyzing ? 'Analisando...' : 'Analisar foto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _errorMessage = null);

    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted || photo == null) {
        return;
      }

      setState(() => _selectedPhoto = photo);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.code == 'camera_access_denied' ||
                error.code == 'photo_access_denied'
            ? 'Permissão negada para acessar imagem.'
            : 'Não foi possível selecionar a imagem.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Não foi possível selecionar a imagem.';
      });
    }
  }

  Future<void> _analyzePhoto() async {
    final photo = _selectedPhoto;
    if (photo == null) {
      setState(() {
        _errorMessage = 'Selecione uma imagem antes de analisar.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(analyzeMealPhotoControllerProvider.notifier)
          .analyze(photo);

      if (!mounted) {
        return;
      }

      if (result.items.isEmpty) {
        setState(() {
          _errorMessage = 'A análise não encontrou itens. Tente outra imagem.';
        });
        return;
      }

      final photoBytes = await photo.readAsBytes();

      if (!mounted) {
        return;
      }

      context.go(
        '/meal-analysis-result',
        extra: MealAnalysisResultArgs(
          analysis: result,
          photoBytes: photoBytes,
          photoName: photo.name,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao analisar foto: $error')),
      );
    }
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final XFile? photo;

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = photo;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: selectedPhoto == null
            ? const Center(child: Text('Nenhuma imagem selecionada.'))
            : FutureBuilder<Uint8List>(
                future: selectedPhoto.readAsBytes(),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  );
                },
              ),
      ),
    );
  }
}
