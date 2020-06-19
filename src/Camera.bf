using System;

using BNA.Math;
using BNA;

namespace VoxelViewer
{
	public class Camera
	{
	  	#region -- Fields --
		protected static Camera activeCamera = null;

		protected Matrix4x4 m_projection = Matrix4x4.Identity;
		protected Matrix4x4 m_view = Matrix4x4.Identity;

		protected Vec3 m_position = .(0, 0, 1000);
		protected Vec3 m_angleRad = .(0, 0, 0);

	  	#endregion

	  	#region -- Properties --
		public static Camera ActiveCamera
		{
			get { return activeCamera; }
			set { activeCamera = value; }
		}

		public Matrix4x4 Projection
		{
			get { return m_projection; }
			set { m_projection = value; }
		}

		public Matrix4x4 View
		{
			get { return m_view; }
		}

		public Vec3 Position
		{
			get { return m_position; }
			set { m_position = value; }
		}

		public Vec3 AngleRad//Radian
		{
			get { return m_angleRad; }
			set { m_angleRad = value; }
		}

	

		public float FOV//In degree
		{
			get;
			set;
		}

		public float OrthoWidth { get; set; }
		public float OrthoHeight { get; set; }

		public Game Game { get; set; }

		#endregion


		public this(Game game)
		{
			FOV = 190;//In degree
			Game = game;

			if (ActiveCamera == null)
				ActiveCamera = this;
		}

		public virtual void Update(float _dt)
		{
		  //Ratio = Game.GraphicsDevice.GetViewport().AspectRatio;
			float Ratio = 1.0f;

			m_projection = Matrix4x4.CreatePerspective((FOV / 2.0f), Ratio, 1.0f, 500.0f);//1.74


		  ///////////////////////////////
		  // Update Matrix4x4

			m_view.M11 = 1.00000000f;
			m_view.M12 = 0.00000000f;
			m_view.M13 = 0.00000000f;
			m_view.M14 = 0.00000000f;

			m_view.M21 = 0.00000000f;
			m_view.M22 = 1.00000000f;
			m_view.M23 = 0.00000000f;
			m_view.M24 = 0.00000000f;

			m_view.M31 = 0.00000000f;
			m_view.M32 = 0.00000000f;
			m_view.M33 = 1.00000000f;
			m_view.M44 = 0.00000000f;

			m_view.M41 = 0.00000000f;
			m_view.M42 = 0.00000000f;
			m_view.M43 = 0.00000000f;
			m_view.M44 = 1.00000000f;

			var pos = m_position;
			pos.x = -pos.x;
			pos.y = -pos.y;
			pos.z = -pos.z;
			m_view *= Matrix4x4.Translate(pos);

			m_view *=Matrix4x4.CreateRotationZ(m_angleRad.z);//Roll
			m_view *=Matrix4x4.CreateRotationY(m_angleRad.y);//yaw
			m_view *=Matrix4x4.CreateRotationX(m_angleRad.x);//Pitch
			
		}


	}
	
	/// <summary>
	/// Orbit Camera
	/// </summary>
	public class OrbitCamera : Camera
	{
		Vec3 m_targetPos;
		public Vec3 TargetPosition
		{
			get { return m_targetPos; }
			set { m_targetPos = value; }
		}

		public float TargetDistance { get; set; }


		public this(Game game) : base (game)
		{
			TargetDistance = 100;
		}

		public override void Update(float _dt)
		{

			var rotPitch = Matrix4x4.CreateRotationX(m_angleRad.x);//Pitch
			var rotYaw = Matrix4x4.CreateRotationY(m_angleRad.y);//yaw

			Vec3 v = Vec3.Backward * TargetDistance;
			v = Vec3.Transform(v, ref rotPitch);
			v = Vec3.Transform(v, ref rotYaw);

			Position = TargetPosition + v;

			//Init Matrices
			//Ratio = Game.GraphicsDevice.Viewport.AspectRatio;
			float Ratio = 1.33333337f;

			m_projection = Matrix4x4.CreatePerspective((FOV / 2.0f) , Ratio, 1f, 500.0f);

			m_view = Matrix4x4.CreateLookAt(Position, TargetPosition, Vec3.Up);
		}

	}
}
