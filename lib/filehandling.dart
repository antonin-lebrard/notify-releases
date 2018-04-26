part of lib;


class FileToBlock {
  File fileToBlock;
  bool isBlocked = false;
  StreamController<bool> _noLongerBlocked = new StreamController<bool>.broadcast();
  Stream<bool> noLongerBlocked;
  FileToBlock(String path){
    if (Directory.current.path.endsWith("bin"))
      fileToBlock = new File(path);
    else
      fileToBlock = new File("bin/" + path);
    noLongerBlocked = _noLongerBlocked.stream;
  }

  /**
   * [toDoDuringBlock] has to be synced
   */
  dynamic block(dynamic toDoDuringBlock()) {
    isBlocked = true;
    dynamic res = toDoDuringBlock();
    isBlocked = false;
    _noLongerBlocked.add(true);
    return res;
  }

  Future<dynamic> asyncBlock(Future<dynamic> toDoDuringBlock()) async {
    isBlocked = true;
    dynamic res = await toDoDuringBlock();
    isBlocked = false;
    _noLongerBlocked.add(true);
    return res;
  }

}

class FileHandling {

  static FileToBlock lastFMList = new FileToBlock("lastFMList.json");

  static FileToBlock mbLastRelease = new FileToBlock("mbLastRelease.json");

  static FileToBlock batchReleaseToNotify = new FileToBlock("batch.json");

  static FileToBlock webBatchRelease = new FileToBlock("webBatch.json");

  /**
   * Perform a guaranteed sequential read and write of the [file].
   * The [processContent] function receives the content of the [file],
   * it should return a String corresponding to what's should be written in the [file]
   * Only returning null will not trigger the write
   *
   * This function assures the user that between the read and the write,
   * the [file] will not be modified by another part of the app
   */
  static Future blockedFileOperation(FileToBlock file, String processContent(String fileContent)) {
    Completer completer = new Completer();
    if (!file.isBlocked) {
      file.block(() {
        try {
          String res = processContent(file.fileToBlock.readAsStringSync());
          if (res != null)
            file.fileToBlock.writeAsStringSync(res);
        } catch (error, stacktrace) {
          print(error);
          print(stacktrace);
        }
      });
      completer.complete(null);
    } else {
      StreamSubscription<bool> sub;
      sub = file.noLongerBlocked.listen((bool isNoLongerBlocked) {
        if (isNoLongerBlocked) {
          sub.cancel();
          file.block(() {
            try {
              String res = processContent(file.fileToBlock.readAsStringSync());
              if (res != null)
                file.fileToBlock.writeAsStringSync(res);
            } catch (error, stacktrace) {
              print(error);
              print(stacktrace);
            }
          });
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  /**
   * Same as [blockedFileOperation] but accepts an async [processContent] function
   */
  static Future blockedAsyncFileOperation(FileToBlock file, Future<String> processContent(String fileContent)) async {
    Completer completer = new Completer();
    if (!file.isBlocked) {
      file.asyncBlock(() async {
        try {
          String res = await processContent(file.fileToBlock.readAsStringSync());
          if (res != null)
            file.fileToBlock.writeAsStringSync(res);
        } catch (error, stacktrace) {
          print(error);
          print(stacktrace);
        }
      });
      completer.complete(null);
    } else {
      StreamSubscription<bool> sub;
      sub = file.noLongerBlocked.listen((bool isNoLongerBlocked) async {
        if (isNoLongerBlocked) {
          sub.cancel();
          file.asyncBlock(() async {
            try {
              String res = await processContent(file.fileToBlock.readAsStringSync());
              if (res != null)
                file.fileToBlock.writeAsStringSync(res);
            } catch (error, stacktrace) {
              print(error);
              print(stacktrace);
            }
          });
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  static Future<String> readFile(FileToBlock file){
    Completer<String> completer = new Completer<String>();
    if (!file.isBlocked){
      completer.complete(_readFile(file));
    } else {
      StreamSubscription<bool> sub;
      sub = file.noLongerBlocked.listen((bool isNoLongerBlocked){
        if (isNoLongerBlocked) {
          sub.cancel();
          completer.complete(_readFile(file));
        }
      });
    }
    return completer.future;
  }

  static String _readFile(FileToBlock file){
    return file.block((){
      return file.fileToBlock.readAsStringSync();
    });
  }
}