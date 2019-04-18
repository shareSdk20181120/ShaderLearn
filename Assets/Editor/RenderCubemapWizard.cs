using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class RenderCubemapWizard : ScriptableWizard
{
    public Transform renderFromTrans;
    public Cubemap cubeMap;//这里的Cubemap 在Inspector里 Readable必须设置true

    private void OnWizardUpdate()
    {
        helpString = "Select transform to render from and cubemap to render into";
        isValid = (renderFromTrans != null) && (cubeMap != null);
    }

    private void OnWizardCreate()
    {
        GameObject go = new GameObject();
        Camera camera= go.AddComponent<Camera>();
        go.transform.position = renderFromTrans.position;
        camera.RenderToCubemap(cubeMap);//把从当前位置观察到的图像渲染到指定的立方体纹理中
        DestroyImmediate(go);
    }

    [MenuItem("GameObject/Render to cubemap")]
    static void RenderCubemap()
    {
        ScriptableWizard.DisplayWizard<RenderCubemapWizard>("Render cubemap", "Rendere");
    }
}
