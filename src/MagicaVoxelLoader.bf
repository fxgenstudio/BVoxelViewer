using BNA.Graphics;
using System.Diagnostics;
using System;
using System.IO;

namespace VoxelViewer
{
		/// <summary>
		/// Voxel Desc
		/// </summary>
		public struct VoxelDesc
		{
		    public int x, y, z, i;
		}

		/// <summary>
		/// MagicaVoxel model Loader
		/// https://ephtracy.github.io/index.html?page=mv_vox_format
		/// </summary>
		public class MagicaVoxelLoader
		{
		    Color[] m_palette;
		    public Color[] Palette { get { return m_palette; } }

		    CubeArray3D m_carray;
		    public CubeArray3D Array { get { return m_carray; } }


		    public this()
		    {
		        m_carray = new CubeArray3D();
		        m_palette = new Color[256];
		    }

			public ~this()
			{
				m_carray.Clear();
				delete m_carray;
				delete m_palette;

			}


		    /// <summary>
		    /// Read .VOX File and return a CubeArray3D
		    /// </summary>
		    /// <param name="_strPath"></param>
		    /// <returns></returns>
		    //public bool ReadFile(Windows.Storage.Streams.DataReader _br)
		    public bool ReadFile(Stream _stream)
		    {
				//StreamReader reader;
				//reader.Read()

		        //////////////////////////////////////////////////
		        //Read Header
		        //4 bytes: magic number ('V' 'O' 'X' 'space' )
		        //4 bytes: version number (current version is 150 )
		        uint32 signature = _stream.Read<uint32>();
		        if (signature != (uint32)0x20584F56)  //56 4F 58 20
		        {
		            Debug.WriteLine("Not an MagicaVoxel File format");
		            return false;
		        }

		        uint32 version = _stream.Read<uint32>();
		        if (version < (uint32)150)
		        {
		            Debug.WriteLine("MagicaVoxel version too old");
		            return false;
		        }


		        // header
		        //4 bytes: chunk id
		        //4 bytes: size of chunk contents (n)
		        //4 bytes: total size of children chunks(m)

		        //// chunk content
		        //n bytes: chunk contents

		        //// children chunks : m bytes
		        //{ child chunk 0 }
		        //{ child chunk 1 }
		        int sizeX, sizeY, sizeZ;
		        sizeX = sizeY = sizeZ = 0;
		        int numVoxels = 0;
		        int offsetX, offsetY, offsetZ;
		        offsetX = offsetY = offsetZ = 0;

		        SmallCube cube;

		        while (_stream.Position < _stream.Length)
		        {

					uint32 chunkName = _stream.Read<uint32>();
		            //String chunkName = new String(_stream.Read() ReadChars(4));
#unwarn
		            uint32 chunkSize = _stream.Read<uint32>();
#unwarn
		            uint32 chunkTotalChildSize = _stream.Read<uint32>();


					//53495a45
		            if (chunkName == 0x455a4953)	//"SIZE"
		            {
		                //(4 bytes x 3 : x, y, z ) 
		                sizeX = (int)_stream.Read<uint32>();
		                sizeY = (int)_stream.Read<uint32>();
		                sizeZ = (int)_stream.Read<uint32>();

		                //Align size to chunk size
		                int sx = sizeX + ((CubeArray3D.CHUNKSIZE - (sizeX % CubeArray3D.CHUNKSIZE)) % CubeArray3D.CHUNKSIZE);
		                int sy = sizeY + ((CubeArray3D.CHUNKSIZE - (sizeY % CubeArray3D.CHUNKSIZE)) % CubeArray3D.CHUNKSIZE);
		                int sz = sizeZ + ((CubeArray3D.CHUNKSIZE - (sizeZ % CubeArray3D.CHUNKSIZE)) % CubeArray3D.CHUNKSIZE);

		                m_carray.SetSize(sx, sz, sy); //Reversed y-z

		                offsetX = (sx - sizeX) >> 1;
		                offsetY = (sz - sizeZ) >> 1;//Reversed y-z
		                offsetZ = (sy - sizeY) >> 1;//Reversed y-z

		            }
		            else if (chunkName == 0x495a5958) //"XYZI"
		            {
						//58595a49
		                //(numVoxels : 4 bytes )
		                //(each voxel: 1 byte x 4 : x, y, z, colorIndex ) x numVoxels
		                numVoxels = (int)_stream.Read<uint32>();
		                while (numVoxels > 0)
		                {
		                    uint8 vx = _stream.Read<uint8>();
		                    uint8 vy = _stream.Read<uint8>();
		                    uint8 vz = _stream.Read<uint8>();
		                    uint8 vi = _stream.Read<uint8>();
		                    cube.byMatL0 = vi;
		                    m_carray.SetCube(offsetX + (int)vx, offsetY + (int)vz, m_carray.CUBESIZEZ - (int)vy - 1 - offsetZ, cube);  //Reserved y-z

		                    numVoxels--;
		                }
		            }
		            else if (chunkName == 0x41424752)	//"RGBA"
		            {
						//52474241
		                //(each pixel: 1 byte x 4 : r, g, b, a ) x 256
		                for (int i = 0; i < 256; i++)
		                {
		                    uint8 r = _stream.Read<uint8>();
		                    uint8 g = _stream.Read<uint8>();
		                    uint8 b = _stream.Read<uint8>();
		                    uint8 a = _stream.Read<uint8>();

		                    m_palette[i].r = r;
							m_palette[i].g = g;
							m_palette[i].b = b;
							m_palette[i].a = a;
		                }



		            }
		        }

		        return true;
		    }

		}



}
