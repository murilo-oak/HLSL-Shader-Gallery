using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightAnimation : MonoBehaviour
{
    [Range(0f,1f)]
    public float speed = 1f;
    private void OnDrawGizmos()
    {
        Quaternion rot = Quaternion.Euler(transform.rotation.eulerAngles);
        Quaternion rot2 = Quaternion.Euler(0, speed, 0);

        transform.rotation *= rot2;
    }

    private void Update()
    {
        Quaternion rot = Quaternion.Euler(transform.rotation.eulerAngles);
        Quaternion rot2 = Quaternion.Euler(0, speed, 0);

        transform.rotation *= rot2;
    }
}
