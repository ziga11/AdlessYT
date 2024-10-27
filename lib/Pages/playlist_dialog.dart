import 'package:adless_youtube/Fetch/youtube_api.dart';
import 'package:flutter/material.dart';

class PlaylistDialog extends StatefulWidget {
  const PlaylistDialog({super.key});

  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Playlist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Playlist Title',
              hintText: 'Enter playlist title',
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Enter playlist description',
            ),
          ),
          CheckboxListTile(
            title: const Text('Private Playlist'),
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final playlistId = await YoutubeFetch.createPlaylist(
              title: _titleController.text,
              description: _descriptionController.text,
              isPrivate: _isPrivate,
            );

            if (playlistId != null) {
              Navigator.pop(context, playlistId);
            } else {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create playlist')),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

