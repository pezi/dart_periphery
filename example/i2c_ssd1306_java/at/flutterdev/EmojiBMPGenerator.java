package at.flutterdev;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.File;
import bsh.Interpreter;

import java.util.Base64;

import javax.imageio.ImageIO;

// dart run jnigen --config jnigen.yaml
// https://dart.dev/interop/java-interop
// https://snapcraft.io/install/flutter/raspbian

// size 64 offset 10
public class EmojiBMPGenerator {

    static String TEXT_SCRIPT =
            "int midY = height / 2;\n" +
            "int amplitude = height / 3;\n" +
            "double frequency = 2 * Math.PI / width;\n" +

            "for (int x = 0; x < width; x++) {\n" +
            "    int y = midY + (int) (amplitude * Math.sin(frequency * x));\n" +
            "    image.setRGB(x, y, Color.WHITE.getRGB());\n" +
            "}\n";

    public static String createEmojiBMP(String emoji, int size, int offset) {
        try {
            System.setProperty("java.awt.headless", "true");

            int width = 128;
            int height = 64;
            // Create a binary BufferedImage
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_BINARY);

            Graphics2D g2d = image.createGraphics();
            // Set background to white
            g2d.setColor(Color.BLACK);
            g2d.fillRect(0, 0, width, height);

            // Set emoji color and font
            g2d.setColor(Color.WHITE);
            g2d.setFont(new Font("Segoe UI Emoji", Font.PLAIN, size));

            // Center the emoji
            // String emoji = "💩";
            FontMetrics fm = g2d.getFontMetrics();
            int x = (width - fm.stringWidth(emoji)) / 2;
            int y = height - offset;

            // Draw the emoji
            g2d.drawString(emoji, x, y);
            g2d.dispose();
            // Extract raw pixel data from BufferedImage
            byte[] imageBytes = ((DataBufferByte) image.getRaster().getDataBuffer()).getData();
            // Encode pixel data as Base64
            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (Exception e) {
            e.printStackTrace();

            return e.getMessage();
        }

    }

    public static String script(String script) {
        try {
            System.setProperty("java.awt.headless", "true");

            int width = 128;
            int height = 64;
            // Create a binary BufferedImage
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_BINARY);

            Graphics2D g2d = image.createGraphics();
            // Set background to white
            g2d.setColor(Color.BLACK);
            g2d.fillRect(0, 0, width, height);

            // Set emoji color and font
            g2d.setColor(Color.WHITE);

            Interpreter i = new bsh.Interpreter();
            i.set("image", image);
            i.set("g2d",g2d);
            i.set("width",width);
            i.set("height",height);
            i.eval(script);
            

            g2d.dispose();
            // Extract raw pixel data from BufferedImage
            byte[] imageBytes = ((DataBufferByte) image.getRaster().getDataBuffer()).getData();
         
        


            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (Exception e) {
            e.printStackTrace();

            return e.getMessage();
        }
    }

    public static void main(String[] args) {
        System.out.println(EmojiBMPGenerator.script("test"));
        /*
            // Encode pixel data as Base64

            File output = new File("sine_wave.png");
            ImageIO.write(image, "png", output);
            System.out.println("Sine wave image saved as sine_wave.png");
         */
    }

}
