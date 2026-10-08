import { fileIo, fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Minimal local file storage in the app sandbox, the pattern is "write/copy in, read back, clean up"
 *
 * Sandbox access needs NO permission.
 */
export class FileStore {
  private dir: string = '';

  /** Creates the working directory under the app sandbox. Call once. */
  init(context: common.Context): void {
    this.dir = `${context.filesDir}/media`;
    try {
      if (!fileIo.accessSync(this.dir)) {
        fileIo.mkdirSync(this.dir);
      }
    } catch (err) {
      FileStore.logErr('init', err);
    }
  }

  /** Writes bytes to <dir>/<name>, replacing any existing file. '' on failure. */
  write(name: string, data: ArrayBuffer): string {
    const path: string = `${this.dir}/${name}`;
    let file: fileIo.File | undefined;
    try {
      file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, data);
      return path;
    } catch (err) {
      FileStore.logErr('write', err);
      return '';
    } finally {
      FileStore.closeQuietly(file);
    }
  }

  /** Copies an external file (e.g. a camera/gallery picker URI) into storage. '' on failure. */
  importFile(sourceUri: string, name: string): string {
    const path: string = `${this.dir}/${name}`;
    let src: fileIo.File | undefined;
    try {
      // A picker URI grants only temporary read access, so copy it in to keep it.
      src = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);
      fileIo.copyFileSync(src.fd, path);
      return path;
    } catch (err) {
      FileStore.logErr('importFile', err);
      return '';
    } finally {
      FileStore.closeQuietly(src);
    }
  }

  /** Reads a stored file back into memory. Empty buffer on failure. */
  read(path: string): ArrayBuffer {
    let file: fileIo.File | undefined;
    try {
      file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      const size: number = fileIo.statSync(file.fd).size;
      const buffer: ArrayBuffer = new ArrayBuffer(size);
      fileIo.readSync(file.fd, buffer);
      return buffer;
    } catch (err) {
      FileStore.logErr('read', err);
      return new ArrayBuffer(0);
    } finally {
      FileStore.closeQuietly(file);
    }
  }

  exists(path: string): boolean {
    if (path.length === 0) {
      return false;
    }
    try {
      return fileIo.accessSync(path);
    } catch (err) {
      return false;
    }
  }

  remove(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      fileIo.unlinkSync(path);
    } catch (err) {
      // Nothing to delete — safe to ignore.
    }
  }

  /** file:// URI that Image / Video / AVPlayer accept directly. */
  toUri(path: string): string {
    if (path.length === 0) {
      return '';
    }
    try {
      return fileUri.getUriFromPath(path);
    } catch (err) {
      return '';
    }
  }

  // Closes a descriptor without masking the original error (used in finally).
  private static closeQuietly(file: fileIo.File | undefined): void {
    if (file === undefined) {
      return;
    }
    try {
      fileIo.closeSync(file);
    } catch (err) {
      // ignore
    }
  }

  private static logErr(where: string, err: Object): void {
    const e = err as BusinessError;
    console.error(`FileStore ${where} failed: ${e.code} - ${e.message}`);
  }
}
