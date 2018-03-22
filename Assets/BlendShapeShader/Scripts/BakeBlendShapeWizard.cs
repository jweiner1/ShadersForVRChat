#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text.RegularExpressions;

public class BakeBlendShapeWizard : ScriptableWizard {
	public SkinnedMeshRenderer mesh;
	public bool precise = true;
	public int[] selected = new int[4];
	public bool startBake = false;
	public bool finishBake = false;
	enum BakeType { DeltaPosition, DeltaTangent, DeltaNormal };

	[MenuItem("GameObject/Bake Blend Shapes")]
	static void CreateWizard() {
		BakeBlendShapeWizard wiz = ScriptableWizard.DisplayWizard<BakeBlendShapeWizard>("Bake Blend Shapes");
		wiz.selected [0] = -1;
		foreach (GameObject obj in Selection.gameObjects) {
			foreach (SkinnedMeshRenderer sm in obj.GetComponentsInChildren<SkinnedMeshRenderer>()) {
				wiz.mesh = sm;
				return;
			}
		}
	}
	void Bake(int blendShapeID, BakeType type, int dest) {
		Mesh m = mesh.sharedMesh;
		if (!m) {
			throw new UnityException ("Bad mesh.");
		}
		List<Vector3> normals = new List<Vector3> ();
		m.GetNormals (normals);
		List<Vector4> tangents = new List<Vector4> ();
		m.GetTangents (tangents);
		Vector3[] deltaPositions = new Vector3[m.vertexCount];
		Vector3[] deltaNormals = new Vector3[m.vertexCount];
		Vector3[] deltaTangents = new Vector3[m.vertexCount];
		m.GetBlendShapeFrameVertices (blendShapeID, 0, deltaPositions, deltaNormals, deltaTangents);
		List<Vector3> uv = new List<Vector3> ();
		switch (type) {
		case BakeType.DeltaPosition:
			for (int i = 0; i < m.vertexCount; i++) { // We bake positions using the normals and tangents as an orthogonal basis.
				Vector3 DP = deltaPositions [i];
				Vector3 X = normals [i];
				Vector3 Y = new Vector3 (tangents [i].x, tangents [i].y, tangents [i].z);
				Vector3 Z = Vector3.Cross (X, Y);
				Vector3.OrthoNormalize (ref X, ref Y, ref Z);
				Matrix4x4 toNewSpace = new Matrix4x4 ();
				toNewSpace.SetRow (0, X);
				toNewSpace.SetRow (1, Y);
				toNewSpace.SetRow (2, Z);
				toNewSpace [3, 3] = 1.0F;
				Vector3 XYZ = toNewSpace.MultiplyPoint (DP);
				uv.Add (XYZ);
			}
			break;
		case BakeType.DeltaNormal:
			for (int i = 0; i < m.vertexCount; i++) {
				uv.Add (deltaNormals [i]);
			}
			break;
		case BakeType.DeltaTangent:
			for (int i = 0; i < m.vertexCount; i++) {
				uv.Add (deltaTangents [i]);
			}
			break;
		}
		if (dest <= 3) {
			m.SetUVs (dest, uv);
		} else if (dest == 4) { // There is no uv destination higher than 3! But we can sneak a vec3 into uv1.w, uv2.w, and uv3.w....
			List<Vector4> uv1 = new List<Vector4>();
			List<Vector4> uv2 = new List<Vector4>();
			List<Vector4> uv3 = new List<Vector4>();
			m.GetUVs (1, uv1);
			m.GetUVs (2, uv2);
			m.GetUVs (3, uv3);
			for (int i = 0; i < uv.Count; i++) {
				uv1 [i] = new Vector4(uv1[i].x, uv1[i].y, uv1[i].z, uv[i].x);
				uv2 [i] = new Vector4(uv2[i].x, uv2[i].y, uv2[i].z, uv[i].y);
				uv3 [i] = new Vector4(uv3[i].x, uv3[i].y, uv3[i].z, uv[i].z);
			}
			m.SetUVs (1, uv1);
			m.SetUVs (2, uv2);
			m.SetUVs (3, uv3);
		} else {
			throw new UnityException ("Yeah, there's no uv destination that high, bud.");
		}
	}
	void OnGUI() {
		EditorGUILayout.HelpBox ("Baking blendshapes is a non-destructive task, but this means that if you reload the project or reimport the model the information is lost!", MessageType.Info);
		mesh = (SkinnedMeshRenderer)EditorGUILayout.ObjectField("Skinned Mesh", mesh, typeof(SkinnedMeshRenderer), true);
		precise = EditorGUILayout.Toggle ( new GUIContent("Pack norm/tang deltas", "Use UV2 and UV3 to pack delta normals, and delta tangents respectively. This reduces the number of blendshapes you can bake!"), precise);
		if (mesh) {
			// Generate names
			List<string> blendShapeNames = new List<string>();
			for (int i = 0; i < mesh.sharedMesh.blendShapeCount; i++) {
				blendShapeNames.Add (mesh.sharedMesh.GetBlendShapeName (i));
				if (selected[0] == -1 && mesh.sharedMesh.GetBlendShapeName (i) == "Intersect") {
					selected [0] = i;
				}
			}
			if ( !precise ) {
				EditorGUILayout.HelpBox ("Blend Shape 1 -> UV1\nBlend Shape 2 -> UV2\nBlend Shape 3 -> UV3\nBlend Shape 4 -> {UV1.w,UV2.w,UV3.w}", MessageType.Info);
				for (int i = 0; i < 4; i++) {
					selected[i] = EditorGUILayout.Popup ("Blend Shape " + i + ":", selected[i], blendShapeNames.ToArray ());
				}
			} else {
				EditorGUILayout.HelpBox ("Delta Position -> UV1\nDelta Normals -> UV2\nDelta Tangents -> UV3", MessageType.Info);
				selected[0] = EditorGUILayout.Popup ("Blend Shape:", selected[0], blendShapeNames.ToArray ());
			}
		}
		EditorGUILayout.Space ();
		if (mesh && GUILayout.Button ("Bake!")) {
			if (precise) {
				startBake = true;
				Bake (selected [0], BakeType.DeltaPosition, 1);
				Bake (selected [0], BakeType.DeltaNormal, 2);
				Bake (selected [0], BakeType.DeltaTangent, 3);
				startBake = false;
				finishBake = true;
			} else {
				startBake = true;
				for (int i = 0; i < 4; i++) {
					Bake (selected [i], BakeType.DeltaPosition, i+1);
				}
				startBake = false;
				finishBake = true;
			}
		}
		if (startBake && !finishBake) {
			EditorGUILayout.Space ();
			EditorGUILayout.HelpBox ("Failed to bake! Check console for errors.", MessageType.Error);
		} else if (finishBake) {
			EditorGUILayout.Space ();
			startBake = false;
			EditorGUILayout.HelpBox ("Done! :)", MessageType.Info);
		}
	}
}
#endif