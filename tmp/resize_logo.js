
const Jimp = require('jimp');
const path = require('path');

const inputPath = path.join(__dirname, '..', 'assets', 'images', 'logo.png');
const outputPath = path.join(__dirname, '..', 'assets', 'images', 'launcher_foreground.png');

async function resize() {
  try {
    const image = await Jimp.read(inputPath);
    console.log('Original image dimensions:', image.bitmap.width, 'x', image.bitmap.height);

    // Step 1: Auto-crop whitespace from the logo
    // We'll manually find the bounding box of non-white pixels
    const w = image.bitmap.width;
    const h = image.bitmap.height;
    let minX = w, minY = h, maxX = 0, maxY = 0;

    image.scan(0, 0, w, h, function(x, y, idx) {
      const r = this.bitmap.data[idx];
      const g = this.bitmap.data[idx + 1];
      const b = this.bitmap.data[idx + 2];
      const a = this.bitmap.data[idx + 3];
      
      // Consider a pixel "non-white" if it's not close to white or transparent
      const isWhite = (r > 240 && g > 240 && b > 240) || a < 20;
      if (!isWhite) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    });

    console.log('Content bounds:', minX, minY, maxX, maxY);
    const contentWidth = maxX - minX + 1;
    const contentHeight = maxY - minY + 1;
    console.log('Content size:', contentWidth, 'x', contentHeight);

    // Step 2: Crop to content bounds
    const cropped = image.crop(minX, minY, contentWidth, contentHeight);
    console.log('Cropped dimensions:', cropped.bitmap.width, 'x', cropped.bitmap.height);

    // Step 3: Create a 1024x1024 canvas with white background
    const canvas = new Jimp(1024, 1024, 0xFFFFFFFF); // White background

    // Step 4: Scale the cropped logo to fill ~92% of the canvas
    // Android adaptive icons show the inner 66% of the foreground layer,
    // so we need the logo to be BIG in the canvas to look right.
    const targetSize = Math.floor(1024 * 0.92); // 942px
    cropped.scaleToFit(targetSize, targetSize);

    console.log('Scaled dimensions:', cropped.bitmap.width, 'x', cropped.bitmap.height);

    // Step 5: Center it on the canvas
    const x = Math.floor((1024 - cropped.bitmap.width) / 2);
    const y = Math.floor((1024 - cropped.bitmap.height) / 2);

    canvas.composite(cropped, x, y);

    await canvas.writeAsync(outputPath);
    console.log('Processed image saved to:', outputPath);
    console.log('Logo positioned at:', x, y);
  } catch (err) {
    console.error('Error processing image:', err);
    process.exit(1);
  }
}

resize();
