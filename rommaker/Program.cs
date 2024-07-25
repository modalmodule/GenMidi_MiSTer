using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;

namespace rommaker
{
    class Program
    {
        static string TilemapRomPath => $@"{resourceOutputPath}tilemap.bin";

        static string TilemapPath => $@"{resourcePath}tilemap\tilemap.png";
        static string TilemapExtractPath => $@"{resourcePath}tilemap\tilemap_extract.png";
        static string TilemapSourcePath => $@"{sourcePath}tilemap_indexes";

        static string SpriteRomPath => $@"{resourceOutputPath}sprite.bin";

        static string SpritePath => $@"{resourcePath}sprites\";

        static string PalettePath => $@"{resourceOutputPath}palette.bin";

        static string SpriteSourcePath => $@"{sourcePath}sprite_images";

        static string MusicPath => $@"{resourcePath}music\";

        static string MusicTrackListPath => $@"{resourcePath}music\tracks.txt";

        static string MusicRomPath => $@"{resourceOutputPath}music.bin";

        static string MusicSourcePath => $@"{sourcePath}music_tracks";

        static string SoundPath => $@"{resourcePath}sound\";

        static string SoundListPath => $@"{resourcePath}sound\samples.txt";

        static string SoundRomPath => $@"{resourceOutputPath}sound.bin";

        static string SoundSourcePath => $@"{sourcePath}sound_samples";

        static readonly int PaletteMax = 4;
        static readonly int PaletteIndexMax = 32;

        static readonly List<List<Color>> Palettes = new();

        static long musicRomLength = (1024 * 64);

        static void CreateMusicRom()
        {
            Console.WriteLine("CREATING MUSIC ROM");
            if (File.Exists(MusicRomPath)) { File.Delete(MusicRomPath); }

            List<byte> trackData = new();
            string[] trackPos = new string[0];


            StringBuilder builder = new();
            builder.AppendLine("#ifndef MUSIC_TRACKS_H");
            builder.AppendLine("#define MUSIC_TRACKS_H");
            builder.AppendLine("#define const_music_track_max 32");
            builder.AppendLine("extern unsigned long music_track_address[const_music_track_max];");

            if (File.Exists(MusicTrackListPath))
            {

                // Read track list
                string[] tracks = File.ReadAllLines(MusicTrackListPath);
                trackPos = new string[tracks.Length];
                int t = 0;
                uint p = 0;
                foreach (string track in tracks)
                {
                    string file = track.Split("#")[0];
                    string name = track.Split("#")[1];
                    byte[] data = File.ReadAllBytes(MusicPath + file);
                    trackData.AddRange(data);
                    trackPos[t] = p + "u";

                    builder.AppendLine($"#define const_music_{name} {t}");
                    Console.WriteLine($"\t{t} - {p} > {file}");
                    p += (uint)data.Length;
                    t++;
                }

            }

            //while (trackData.Count < musicRomLength)
            //{
            //    trackData.Add(0);
            //}

            builder.AppendLine("#endif");
            File.WriteAllText(MusicSourcePath + ".h", builder.ToString());

            builder = new StringBuilder();
            builder.AppendLine("#ifndef MUSIC_TRACKS_C");
            builder.AppendLine("#define MUSIC_TRACKS_C");
            builder.AppendLine("#include \"music_tracks.h\"");
            if (trackPos.Length > 0)
            {
                builder.AppendLine("unsigned long music_track_address[] = {" + string.Join(",", trackPos) + "};");
            }
            else
            {
                builder.AppendLine("unsigned long music_track_address[] = {0u};");
            }
            builder.AppendLine("#endif");
            File.WriteAllText(MusicSourcePath + ".c", builder.ToString());

            File.WriteAllBytes(MusicRomPath, trackData.ToArray());


        }

        static void CreateSoundRom()
        {
            Console.WriteLine("CREATING SOUND ROM");
            if (File.Exists(SoundRomPath)) { File.Delete(SoundRomPath); }

            // Read sample list

            string[] samples = { };
            if (File.Exists(SoundListPath))
            {
                samples = File.ReadAllLines(SoundListPath);
            }

            List<byte> soundData = new();
            string[] soundPos = new string[samples.Length];
            string[] soundLen = new string[samples.Length];
            string command = $@"C:\Program Files (x86)\sox-14-4-2\sox.exe";
            int t = 0;
            uint p = 0;

            StringBuilder builder = new();
            builder.AppendLine("#ifndef SOUND_SAMPLES_H");
            builder.AppendLine("#define SOUND_SAMPLES_H");
            builder.AppendLine("#define const_sound_sample_max 32");
            builder.AppendLine("extern unsigned long sound_sample_address[const_sound_sample_max];");
            builder.AppendLine("extern unsigned long sound_sample_length[const_sound_sample_max];");
            builder.AppendLine($"#define const_sound_sample_used {samples.Length}");

            foreach (string sample in samples)
            {
                string file = sample.Split("#")[0];
                string name = sample.Split("#")[1];

                if (!File.Exists($"{SoundPath}{file}.vox") || File.GetLastWriteTimeUtc($"{SoundPath}{file}.wav") > File.GetLastWriteTimeUtc($"{SoundPath}{file}.vox"))
                {
                    string args = $"{SoundPath}{file}.wav {SoundPath}{file}.vox rate 8k";
                    Process.Start(command, args).WaitForExit();
                }
                byte[] data = File.ReadAllBytes($"{SoundPath}{file}.vox");
                soundData.AddRange(data);
                soundPos[t] = p + "u";
                uint l = (uint)data.Length;
                soundLen[t] = l + "u";
                builder.AppendLine($"#define const_sound_{name} {t}");
                Console.WriteLine($"\t{t} - {p} > {file}");
                p += l;
                t++;
            }


            builder.AppendLine("#endif");
            File.WriteAllText(SoundSourcePath + ".h", builder.ToString());

            builder = new StringBuilder();
            builder.AppendLine("#ifndef SOUND_SAMPLES_C");
            builder.AppendLine("#define SOUND_SAMPLES_C");
            builder.AppendLine("#include \"sound_samples.h\"");
            if (soundPos.Length > 0)
            {
                builder.AppendLine("unsigned long sound_sample_address[] = {" + string.Join(",", soundPos) + "};");
                builder.AppendLine("unsigned long sound_sample_length[] = {" + string.Join(",", soundLen) + "};");
            }
            else
            {
                builder.AppendLine("unsigned long sound_sample_address[] = {0u};");
                builder.AppendLine("unsigned long sound_sample_length[] = {0u};");
            }
            builder.AppendLine("#endif");
            File.WriteAllText(SoundSourcePath + ".c", builder.ToString());

            File.WriteAllBytes(SoundRomPath, soundData.ToArray());

        }

        static void CreateSpriteRom()
        {

            for (int p = 0; p < PaletteMax; p++)
            {
                Palettes.Add(new List<Color>());
                Palettes[p].Add(Color.FromArgb(0, 0, 0, 0));
            }

            if (File.Exists(SpriteRomPath)) { File.Delete(SpriteRomPath); }
            if (File.Exists(PalettePath)) { File.Delete(PalettePath); }

            Dictionary<string, string> spriteSourceItems = new();

            if (Directory.Exists(SpritePath))
            {

                FileStream spriteStream = File.OpenWrite(SpriteRomPath);
                BinaryWriter spriteStreamWriter = new(spriteStream, Encoding.Default);

                uint pos = 0;


                int[] groups = { 32, 16, 8 };

                Dictionary<int, MemoryStream> groupStreams = new();
                int groupIndex = groups.Length - 1;
                for (int gi = 0; gi < groups.Length; gi++)
                {
                    int g = groups[gi];
                    int index = 0;
                    ushort groupStartPos = (ushort)(pos + (groups.Length * 2));
                    byte[] groupStartBytes = BitConverter.GetBytes(groupStartPos);
                    Console.WriteLine($"Starting image group {g} at {groupStartPos}");
                    spriteStreamWriter.Write(groupStartBytes[1]); // Write start point for size group
                    spriteStreamWriter.Write(groupStartBytes[0]); // Write start point for size group

                    MemoryStream groupStream = new();
                    ushort groupLen = 0;
                    foreach (string image in Directory.GetFiles(SpritePath, "*.png", SearchOption.TopDirectoryOnly).Where(x => x.Contains($"\\{g}_")))
                    {
                        Bitmap img = new(image);

                        // Remove extension
                        string title = image[0..^4];

                        // Detect palette
                        if (!title.Contains('#'))
                        {
                            throw new Exception("No palette data");
                        }
                        string[] paletteParts = title.Split("#");
                        title = paletteParts[0];
                        int paletteIndex = int.Parse(paletteParts[1]) - 1;

                        // Get name
                        int size = int.Parse(title[(title.LastIndexOf("\\") + 1)..].Split('_')[0]);
                        string name = title.Split("-")[0].Split("_")[1];

                        // Detect slices
                        int imageSizeX = img.Width;
                        int imageSizeY = img.Height;
                        int slicesX = imageSizeX / size;
                        int slicesY = imageSizeY / size;

                        // Add header items
                        spriteSourceItems.Add($"sprite_index_{name}_first", index.ToString());
                        spriteSourceItems.Add($"sprite_index_{name}_count", $"{slicesX * slicesY}");
                        spriteSourceItems.Add($"sprite_index_{name}_last", $"{index + (slicesX * slicesY) - 1}");
                        spriteSourceItems.Add($"sprite_palette_{name}", $"{paletteIndex}");
                        spriteSourceItems.Add($"sprite_size_{name}", $"{gi}");
                        spriteSourceItems.Add($"sprite_pixelsize_{name}", $"{g}");
                        spriteSourceItems.Add($"sprite_halfpixelsize_{name}", $"{g/2}");

                        for (int ys = 0; ys < slicesY; ys++)
                        {
                            for (int xs = 0; xs < slicesX; xs++)
                            {
                                Console.WriteLine($"{index}: {name} - {xs},{ys} --> {pos}");
                                int ymin = ys * size;
                                int ymax = ymin + size;
                                int xmin = xs * size;
                                int xmax = xmin + size;
                                for (int y = ymin; y < ymax; y++)
                                {
                                    for (int x = xmin; x < xmax; x++)
                                    {

                                        Color c = img.GetPixel(x, y);
                                        // Find colour in palette
                                        int pi = -1;
                                        for (int ci = 0; ci < Palettes[paletteIndex].Count; ci++)
                                        {
                                            if (Palettes[paletteIndex][ci] == c)
                                            {
                                                pi = ci;
                                            }
                                        }
                                        // Colour not found, add to paletta
                                        if (pi == -1)
                                        {
                                            pi = Palettes[paletteIndex].Count;
                                            if (pi == PaletteIndexMax)
                                            {
                                                //   throw new Exception("too many colours");

                                                Console.WriteLine($"Palette full: {image} - {xs},{ys} - {pi}, {c}");
                                                pi = 0;
                                            }
                                            else
                                            {
                                                Palettes[paletteIndex].Add(c);
                                                // Console.WriteLine($"Adding to palette: {image} - {xs},{ys} - {pi}, {c}");
                                            }
                                        }

                                        // Write palette index to sprite rom
                                        groupStream.WriteByte(Convert.ToByte(pi));
                                        pos += 1;
                                        groupLen += 1;
                                    }
                                }
                                index++;
                            }
                        }
                    }
                    Console.WriteLine($"Ending image group {g} - length = {groupLen}");
                    groupIndex--;
                    groupStreams.Add(g, groupStream);
                }

                foreach (int g in groups)
                {
                    spriteStreamWriter.Write(groupStreams[g].ToArray());
                }
                spriteStreamWriter.Dispose();
            }

            StringBuilder builder = new();
            builder.AppendLine("#ifndef SPRITE_IMAGES_H");
            builder.AppendLine("#define SPRITE_IMAGES_H");
            foreach (string v in spriteSourceItems.Keys)
            {
                builder.AppendLine("#define " + v + " " + spriteSourceItems[v]);
            }
            builder.AppendLine("#endif");
            File.WriteAllText(SpriteSourcePath + ".h", builder.ToString());

            // Palettes
            foreach (List<Color> palette in Palettes)
            {
                while (palette.Count < PaletteIndexMax)
                {
                    palette.Add(Color.FromArgb(255, 0, 255, 0));
                }
            }

            if (File.Exists(PalettePath))
            {
                File.Delete(PalettePath);
            }
            using (FileStream paletteStream = File.OpenWrite(PalettePath))
            {
                using (BinaryWriter paletteWriter = new(paletteStream, Encoding.BigEndianUnicode))
                {
                    int pi = 0;
                    foreach (List<Color> palette in Palettes)
                    {
                        for (int p = 0; p < palette.Count; p++)
                        {
                            ushort a = (ushort)(palette[p].A == 255 ? 1 : 0);

                            ushort color = (ushort)((palette[p].R / 8) |
                                                   ((palette[p].G / 8) << 5) |
                                                   ((palette[p].B / 8) << 10) |
                                                     a << 15);

                            byte high = (byte)(color >> 8);
                            byte low = (byte)color;

                            // Console.WriteLine($"PALETTE {pi}: {p} - {palette[p]} - {a} - {color.ToString("X2")} - {high} {low}");
                            paletteWriter.Write(high);
                            paletteWriter.Write(low);

                        }
                        pi++;
                    }
                }
            }
        }

        static void CreateTilemapRom()
        {

            if (File.Exists(TilemapRomPath)) { File.Delete(TilemapRomPath); }

            FileStream stream = File.OpenWrite(TilemapRomPath);
            BinaryWriter streamWriter = new(stream, Encoding.Default);

            if (!File.Exists(TilemapPath))
            {
                Console.WriteLine("No tilemap!");
                return;
            }

            Dictionary<ushort, int> colours = new();

            uint pos = 0;
            Bitmap img = new(TilemapPath);
            int size = 16;
            int slicesX = img.Width / size;
            int slicesY = img.Height / size;

            for (int ys = 0; ys < slicesY; ys++)
            {
                for (int xs = 0; xs < slicesX; xs++)
                {
                    int ymin = ys * size;
                    int ymax = ymin + size;
                    int xmin = xs * size;
                    int xmax = xmin + size;
                    for (int y = ymin; y < ymax; y++)
                    {
                        for (int x = xmin; x < xmax; x++)
                        {


                            Color c = img.GetPixel(x, y);
                            ushort a = (ushort)(c.A == 255 ? 1 : 0);
                            ushort color = (ushort)((c.R / 8) |
                                                   ((c.G / 8) << 5) |
                                                   ((c.B / 8) << 10) |
                                                     a << 15);

                            if (colours.ContainsKey(color))
                            {
                                colours[color]++;
                            }
                            else
                            {
                                colours[color] = 1;
                            }

                            byte high = (byte)(color >> 8);
                            byte low = (byte)color;
                            streamWriter.Write(high);
                            streamWriter.Write(low);

                            pos += 1;
                        }
                    }
                }
            }

            streamWriter.Dispose();

            Console.WriteLine($"Tilemap created.  Unique colours={colours.Keys.Count}");

        }

        static void ExtractTilemapRom()
        {

            if (File.Exists(TilemapRomPath)) { File.Delete(TilemapRomPath); }


            Dictionary<ushort, int> colours = new();

            uint pos = 0;
            Bitmap img = new(TilemapExtractPath);
            int size = 16;
            int slicesX = img.Width / size;
            int slicesY = img.Height / size;

            // Find unique tiles in image

            int[,] tileIndexes = new int[slicesX, slicesY];

            Dictionary<string, Tile> tiles = new();
            int droppedTransparent = 0;
            int droppedDuplicate = 0;

            Tile transTile = new Tile();
            tiles.Add(transTile.Hash, transTile);

            int nextTileIndex = 1;



            for (int ys = 0; ys < slicesY; ys++)
            {
                for (int xs = 0; xs < slicesX; xs++)
                {
                    int ymin = ys * size;
                    int ymax = ymin + size;
                    int xmin = xs * size;
                    int xmax = xmin + size;

                    Tile tile = new();
                    bool nonTransparent = false;
                    for (int y = ymin; y < ymax; y++)
                    {
                        for (int x = xmin; x < xmax; x++)
                        {
                            Color c = img.GetPixel(x, y);
                            ushort a = (ushort)(c.A == 255 ? 1 : 0);
                            if (a == 1) { nonTransparent = true; }
                            ushort color = (ushort)((c.R / 8) |
                                                   ((c.G / 8) << 5) |
                                                   ((c.B / 8) << 10) |
                                                     a << 15);
                            tile.Color[x - xmin][y - ymin] = color;
                            if (colours.ContainsKey(color))
                            {
                                colours[color]++;
                            }
                            else
                            {
                                colours[color] = 1;
                            }
                        }
                    }
                    if (nonTransparent)
                    {
                        string hash = tile.Hash;
                        if (!tiles.ContainsKey(hash))
                        {
                            tile.Index = nextTileIndex;
                            nextTileIndex++;
                            tiles[hash] = tile;
                            tileIndexes[xs, ys] = tile.Index;
                        }
                        else
                        {
                            droppedDuplicate++;
                            tileIndexes[xs, ys] = tiles[hash].Index;
                            Console.WriteLine("Hash match found");
                        }
                    }
                    else
                    {
                        droppedTransparent++;
                    }

                }
            }

            FileStream stream = File.OpenWrite(TilemapRomPath);
            BinaryWriter streamWriter = new(stream, Encoding.Default);

            foreach (Tile tile in tiles.Values)
            {
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        byte high = (byte)(tile.Color[x][y] >> 8);
                        byte low = (byte)tile.Color[x][y];
                        streamWriter.Write(high);
                        streamWriter.Write(low);
                        pos += 1;
                    }
                }
            }

            streamWriter.Dispose();

            Console.WriteLine($"Tilemap created.  Next tile index={nextTileIndex} Total tiles={tiles.Count} Dropped Transparent={droppedTransparent } Dropped Duplicate={droppedDuplicate} Unique colours={colours.Keys.Count}");



            StringBuilder builder = new();
            builder.AppendLine("#ifndef TILEMAP_INDEXES_H");
            builder.AppendLine("#define TILEMAP_INDEXES_H");
            builder.AppendLine($"#define const_tilemap_index_x_max {tileIndexes.GetUpperBound(0) + 1}");
            builder.AppendLine($"#define const_tilemap_index_y_max {tileIndexes.GetUpperBound(1) + 1}");
            builder.AppendLine("extern unsigned long tilemap_index[const_tilemap_index_y_max][const_tilemap_index_x_max];");
            builder.AppendLine("#endif");
            File.WriteAllText(TilemapSourcePath + ".h", builder.ToString());

            builder = new StringBuilder();
            builder.AppendLine("#ifndef TILEMAP_INDEXES_C");
            builder.AppendLine("#define TILEMAP_INDEXES_C");
            builder.AppendLine("#include \"tilemap_indexes.h\"");

            builder.AppendLine("unsigned long tilemap_index[const_tilemap_index_y_max][const_tilemap_index_x_max] = {");
            for (int y = 0; y < slicesY; y++)
            {
                builder.Append("{");
                for (int x = 0; x < slicesX; x++)
                {
                    builder.Append($"{tileIndexes[x, y]}");
                    if (x < slicesX - 1) { builder.Append(","); }
                }
                builder.Append("}");
                if (y < slicesY - 1) { builder.AppendLine(","); }
            }
            builder.AppendLine("};");

            builder.AppendLine("#endif");
            File.WriteAllText(TilemapSourcePath + ".c", builder.ToString());


        }

        class Tile
        {
            public ushort[][] Color;
            public int Index;

            public string Hash
            {
                get
                {
                    StringBuilder sb = new StringBuilder();

                    for (int y = 0; y < 16; y++)
                    {
                        for (int x = 0; x < 16; x++)
                        {
                            sb.Append(Color[x][y].ToString() + ",");
                        }

                    }
                    return sb.ToString();
                }
            }

            public Tile()
            {
                Color = new ushort[16][];
                for (int y = 0; y < 16; y++)
                {
                    Color[y] = new ushort[16];
                }
            }
        }


        static string resourcePath;
        static string sourcePath;
        static string resourceOutputPath;

        static void Main(string[] args)
        {
            string rootPath = @"..\..\..\..\";
            string currentProject = File.ReadAllText(rootPath + "CURRENT_PROJECT");

            resourceOutputPath = $@"{rootPath}resources\";
            resourcePath = $@"{resourceOutputPath}{currentProject}\";
            resourceOutputPath = resourcePath;

            sourcePath = $@"{rootPath}src\{currentProject}\";

            CreateSpriteRom();

            if (File.Exists(TilemapPath))
            {
                CreateTilemapRom();
            }
            if (File.Exists(TilemapExtractPath))
            {
                ExtractTilemapRom();
            }

            CreateMusicRom();
            CreateSoundRom();
        }

    }
}
