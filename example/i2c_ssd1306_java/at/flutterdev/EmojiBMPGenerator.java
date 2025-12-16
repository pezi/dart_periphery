// Copyright (c) 2025, the Java project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package at.flutterdev;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.File;
import java.io.FileInputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import bsh.Interpreter;
import javax.imageio.ImageIO;


public class EmojiBMPGenerator {
    static final private int width = 128;
    static final private int height = 64;
    static private Font font = null;

    static String TEST_SCRIPT =
            "int midY = height / 2;\n" +
            "int amplitude = height / 3;\n" +
            "double frequency = 2 * Math.PI / width;\n" +
            "int white = Color.WHITE.getRGB();\n" + 
            "for (int x = 0; x < width; x++) {\n" +
            "    int y = midY + (int) (amplitude * Math.sin(frequency * x));\n" +
            "    image.setRGB(x, y, white);\n" +
            "}\n";

    public static String createEmoji(byte[] emojiData, int size, int offset) {
        try {
            

            System.setProperty("java.awt.headless", "true");
 
            String emoji = new String(emojiData, StandardCharsets.UTF_8); 
            // Create a binary BufferedImage
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_BINARY);

            Graphics2D g2d = image.createGraphics();
            // Set background to white
            g2d.setColor(Color.BLACK);
            g2d.fillRect(0, 0, width, height);

            // Set emoji color and font
            g2d.setColor(Color.WHITE);

            if(font == null) {
                try (FileInputStream fis = new FileInputStream("./font/segoe-ui-emoji.ttf")) {
                    // Warning Noto Color Emoji is not working with a mono color bitmap 
                    font = Font.createFont(Font.TRUETYPE_FONT, fis);
                    font = font.deriveFont(Font.PLAIN, size);
                }
            }

            g2d.setFont(font);

            // Center the emoji
            FontMetrics fm = g2d.getFontMetrics();
            int x = (width - fm.stringWidth(emoji)) / 2;
            int y = height - offset;

            // Draw the emoji
            g2d.drawString(emoji, x, y);
            g2d.dispose();
            // Extract raw pixel data from BufferedImage
            byte[] imageBytes = ((DataBufferByte) image.getRaster().getDataBuffer()).getData();
            
            // for debugging
            // ImageIO.write(image, "png", new File("output.png"));
            
            // Encode pixel data as Base64
            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (Exception e) {
            e.printStackTrace();
            return "Exception "+ e.getMessage();
        }

    }

    public static String script(String script) {
        try {
            System.setProperty("java.awt.headless", "true");

            // Create a binary BufferedImage
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_BINARY);

            Graphics2D g2d = image.createGraphics();
            // Set background to white
            g2d.setColor(Color.BLACK);
            g2d.fillRect(0, 0, width, height);

            // Set emoji color and font
            g2d.setColor(Color.WHITE);

            
            Interpreter i = new bsh.Interpreter();
        
            // pass all needed Java objects to the interpreter
            i.set("image", image);
            i.set("g2d",g2d);
            i.set("width",width);
            i.set("height",height);

            // call script
            i.eval(script);
           
            g2d.dispose();

            // Extract raw pixel data from BufferedImage
            byte[] imageBytes = ((DataBufferByte) image.getRaster().getDataBuffer()).getData();    

            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (Exception e) {
            e.printStackTrace();
            return "Exception " + e.getMessage();
        }
    }

    public static void main(String[] args) {
        System.out.println(EmojiBMPGenerator.createEmoji("💩".getBytes(), 64, 10));
        /*
            // Encode pixel data as Base64

            File output = new File("sine_wave.png");
            ImageIO.write(image, "png", output);
            System.out.println("Sine wave image saved as sine_wave.png");
         */
    }

}
