class FileItem {
  const FileItem(this.name, this.path);

  final String name;
  final String path;

  bool equals(FileItem fileItem) =>
      name == fileItem.name && path == fileItem.path;
}
