import { FileStore } from '../storage/FileStore';
import { common } from '@kit.AbilityKit';

@Entry
@ComponentV2
struct Index {
  private static readonly RAWFILE: string = 'test.jpg';
  private static readonly FILE_NAME: string = 'test.jpg';
  private store: FileStore = new FileStore();
  private path: string = '';
  @Local imageUri: string = '';
  @Local status: string = 'Tap Store to copy test.jpg into the sandbox';

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    this.store.init(context);
  }

  build() {
    Column({ space: 4 }) {
      if (this.imageUri.length > 0) {
        Image(this.imageUri)
          .width('40%')
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .backgroundColor(Color.Gray)
      }

      Button('Store test.jpg')
        .onClick(() => {
          this.storeImage();
        })

      Row({ space: 4 }){
        Button('Retrieve')
          .width('50%')
          .onClick(() => {
            this.retrieveImage();
          })
        Button('Delete')
          .width('50%')
          .onClick(() => {
            this.deleteImage();
          })
      }
      .width('100%')

      Text(this.status)
        .fontColor(Color.Gray)
        .fontSize(12)
        .width('80%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }

  private storeImage(): void {
    const context = this.getUIContext().getHostContext() as common.Context;
    try {
      const bytes: Uint8Array = context.resourceManager.getRawFileContentSync(Index.RAWFILE);
      this.path = this.store.write(Index.FILE_NAME, bytes.buffer as ArrayBuffer);
      this.imageUri = '';
      this.status = this.path.length > 0
        ? `Stored ${bytes.length} bytes at\n${this.store.toUri(this.path)}`
        : 'Store failed';
    } catch (err) {
      const e = err as Error;
      console.error(`Index storeImage failed: ${e.message}`);
      this.status = 'Could not read test.jpg from resources';
    }
  }

  private retrieveImage(): void {
    if (!this.store.exists(this.path)) {
      this.status = 'Nothing stored — tap Store first.';
      return;
    }
    const data: ArrayBuffer = this.store.read(this.path);
    this.imageUri = this.store.toUri(this.path);
    this.status = `Retrieved ${data.byteLength} bytes from the sandbox`;
  }

  private deleteImage(): void {
    if (this.path.length === 0) {
      this.status = 'Nothing to delete.';
      return;
    }
    this.store.remove(this.path);
    this.imageUri = '';
    this.status = this.store.exists(this.path) ? 'Delete failed' : 'Deleted from sandbox';
    this.path = '';
  }
}