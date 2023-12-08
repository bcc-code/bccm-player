import 'package:bccm_player/bccm_player.dart';

class BccmTexture {
  final int textureId;

  BccmTexture._internal(this.textureId);

  static Future<BccmTexture> create() async {
    final textureId = await BccmPlayerInterface.instance.createVideoTexture();
    return BccmTexture._internal(textureId);
  }

  Future<void> dispose() async {
    await BccmPlayerInterface.instance.disposeVideoTexture(textureId);
  }
}
