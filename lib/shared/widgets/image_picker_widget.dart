import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<String> initialImageUrls;
  final Function(List<String>) onImagesChanged;
  final Function(List<File>)? onLocalImagesChanged;
  final int maxImages;
  final bool enabled;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrls = const [],
    required this.onImagesChanged,
    this.onLocalImagesChanged,
    this.maxImages = 5,
    this.enabled = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];
  List<File> _localImages = [];

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ürün Fotoğrafları',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_imageUrls.length + _localImages.length}/${widget.maxImages}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fotoğraf grid'i
        if (_imageUrls.isNotEmpty || _localImages.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  _imageUrls.length +
                  _localImages.length +
                  (widget.enabled &&
                          (_imageUrls.length + _localImages.length) <
                              widget.maxImages
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                // Mevcut fotoğraflar (URL)
                if (index < _imageUrls.length) {
                  return _buildNetworkImageTile(_imageUrls[index], index);
                }

                // Yeni seçilen fotoğraflar (Local)
                final localIndex = index - _imageUrls.length;
                if (localIndex < _localImages.length) {
                  return _buildLocalImageTile(_localImages[localIndex], index);
                }

                // Yeni fotoğraf ekleme butonu
                return _buildAddImageTile();
              },
            ),
          )
        else if (widget.enabled)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildNetworkImageTile(String imageUrl, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          if (widget.enabled)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalImageTile(File imageFile, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFile,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          if (widget.enabled)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          // Yükleniyor göstergesi
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Yükleniyor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf\nEkle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Ürün fotoğrafı ekleyin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En fazla ${widget.maxImages} fotoğraf yükleyebilirsiniz',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if ((_imageUrls.length + _localImages.length) >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'En fazla ${widget.maxImages} fotoğraf ekleyebilirsiniz',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kameradan Çek'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _localImages.add(File(image.path));
        });

        // Değişiklikleri parent'a bildir
        widget.onImagesChanged(_imageUrls);
        widget.onLocalImagesChanged?.call(_localImages);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        final localIndex = index - _imageUrls.length;
        _localImages.removeAt(localIndex);
      }
    });

    // Değişiklikleri parent'a bildir
    widget.onImagesChanged(_imageUrls);
    widget.onLocalImagesChanged?.call(_localImages);
  }

  // Local images'ları al (upload için)
  List<File> get localImages => _localImages;

  // Mevcut URL'leri al
  List<String> get imageUrls => _imageUrls;
}
