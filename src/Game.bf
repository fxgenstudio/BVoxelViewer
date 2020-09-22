using System;
using BNA;
using BNA.Graphics;
using System.IO;
using BNA.Math;
using System.Diagnostics;

namespace VoxelViewer
{
	public class MyGame : Game
	{
		OrbitCamera m_cam;
		CubeBrush m_voxelBrush;
		float m_fAngle;

		public this(StringView title, int windowWidth, int windowHeight, bool fullscreen = false)
			: base(title, windowWidth, windowHeight, fullscreen)
		{
			m_fAngle = 0;
			m_cam = new OrbitCamera(this);
			m_cam.TargetDistance = 200;
		}

		public ~this()
		{
			if (m_voxelBrush!=null)
				delete m_voxelBrush;
			delete m_cam;
		}

		protected override void Initialize()
		{
			//Change Rasterizer State
		/*	RasterizerState rasterizerState = RasterizerState();
			rasterizerState.cullMode = CullMode.CullCounterClockwiseFace;
			GraphicsDevice.ApplyRasterizerState(rasterizerState);


			DepthStencilState depthState = DepthStencilState();
			depthState.depthBufferEnable = true;
			depthState.depthBufferWriteEnable =true;
			depthState.depthBufferFunction = CompareFunction.LessEqual;
			depthState.stencilEnable = false;
			GraphicsDevice.SetDepthStencilState(depthState);*/

			//Load VoxelBrush
			uint32 t0, t1;

			var stream = new FileStream();
			var result = stream.Open(@".\Content\monu1.vox", FileAccess.Read);
			if (result case .Ok)
			{
				var mstream = new MemoryStream();
				t0 = Environment.TickCount;
				stream.CopyTo(mstream);
				mstream.Seek(0);
				t1 = Environment.TickCount;
				Console.WriteLine("Brush file loaded in {0} ms", t1-t0);
				
				t0 = Environment.TickCount;
				MagicaVoxelLoader loader = new MagicaVoxelLoader();
				loader.ReadFile(mstream);
				t1 = Environment.TickCount;
				Console.WriteLine("Brush imported in {0} ms", t1-t0);

				t0 = Environment.TickCount;
				m_voxelBrush = new CubeBrush(this, loader.Array, loader.Palette);
				m_voxelBrush.GenerateMesh();
				m_voxelBrush.ApplyEditorEffect();
				t1 = Environment.TickCount;
				Console.WriteLine("Brush build in {0} ms", t1-t0);

				mstream.Close();
				delete mstream;

				delete loader;
			}
			stream.Close();
			delete stream;


			//Load music


		}

		protected override void Update(GameTime time)
		{
			//Camera 
			m_cam.Update(0);
			//m_cam.TargetDistance-=1;

			//Rotation
			m_fAngle += (float)((float)time.ElapsedTime*50);
			//m_fAngle+=0.1f;

			//Update VoxelBrush world Matrix
			if (m_voxelBrush != null)
			{
			    var mtx = Matrix4x4.Translate(m_voxelBrush.m_vec3Origin);
			    mtx *=Matrix4x4.CreateRotationY(m_fAngle);

				//mtx = Matrix4x4.Identity;
			    m_voxelBrush.m_worldMtx = mtx;
			}
		}

		protected override void Draw(GameTime time)
		{
			GraphicsDevice.Clear(.Target | .DepthBuffer, Color(0, 64, 128), 1f);

			//Display Voxel Model
			if (m_voxelBrush != null)
			{

			    m_voxelBrush.Draw(m_cam.View, m_cam.Projection);
			}


		}

	}
}