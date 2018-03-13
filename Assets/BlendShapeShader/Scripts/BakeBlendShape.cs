#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BakeBlendShape : MonoBehaviour {
	[MenuItem("GameObject/Bake selected skinned meshs' blendshape \"Intersect\" to UV1, UV2, and UV3")]
    private static void BakePos() {
		bool didSomething = false;
		foreach (GameObject obj in Selection.gameObjects) {
			foreach (SkinnedMeshRenderer sm in obj.GetComponentsInChildren<SkinnedMeshRenderer>()) {
				Mesh m = sm.sharedMesh;
				if (!m) {
					continue;
				}
				for (int o = 0; o < m.blendShapeCount; o++) {
					string name = m.GetBlendShapeName (o);
					if (name != "Intersect") {
						continue;
					}
					didSomething = true;
					List<Vector3> normals = new List<Vector3> ();
					m.GetNormals (normals);

					List<Vector4> tangents = new List<Vector4> ();
					m.GetTangents (tangents);

					Vector3[] deltaPositions = new Vector3[m.vertexCount];
					Vector3[] deltaNormals = new Vector3[m.vertexCount];
					Vector3[] deltaTangents = new Vector3[m.vertexCount];
					m.GetBlendShapeFrameVertices (o, 0, deltaPositions, deltaNormals, deltaTangents);
					List<Vector4> uv1 = new List<Vector4> ();
					List<Vector4> uv2 = new List<Vector4> ();
					List<Vector4> uv3 = new List<Vector4> ();
					for (int i = 0; i < m.vertexCount; i++) {
						Vector3 DP = deltaPositions [i];

						Vector3 X = normals [i];
						Vector3 Y = new Vector3(tangents [i].x, tangents [i].y, tangents [i].z);
						Vector3 Z = Vector3.Cross (X, Y);

						Vector3.OrthoNormalize(ref X, ref Y, ref Z);
						Matrix4x4 toNewSpace = new Matrix4x4();
						toNewSpace.SetRow(0, X);
						toNewSpace.SetRow(1, Y);
						toNewSpace.SetRow(2, Z);
						toNewSpace[3, 3] = 1.0F;
						Vector3 XYZ = toNewSpace.MultiplyPoint (DP);
						uv1.Add (new Vector4 (XYZ.x, XYZ.y, XYZ.z, 1));
						uv2.Add (new Vector4 (deltaNormals [i].x, deltaNormals [i].y, deltaNormals [i].z, 1));
						uv3.Add (new Vector4 (deltaTangents [i].x, deltaTangents [i].y, deltaTangents [i].z, 1));
					}
					sm.sharedMesh.SetUVs (1, uv1);
					sm.sharedMesh.SetUVs (2, uv2);
					sm.sharedMesh.SetUVs (3, uv3);
				}
			}
		}
		if (!didSomething) {
			Debug.LogError ("No skinned meshes found, or the mesh didn't have a blendshape named \"Intersect\"!");
		} else {
			Debug.Log ("Done!");
		}
    }
}
#endif