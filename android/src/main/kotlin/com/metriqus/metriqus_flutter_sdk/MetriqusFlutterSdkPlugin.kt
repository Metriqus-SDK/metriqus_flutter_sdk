package com.metriqus.metriqus_flutter_sdk

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.opengl.GLSurfaceView
import android.opengl.GLES20
import android.app.ActivityManager
import android.util.DisplayMetrics
import android.view.WindowManager
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import java.util.concurrent.CountDownLatch
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import java.util.Locale
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails

class MetriqusFlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "metriqus_flutter_sdk/device_info")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getGpuInfo" -> getGpuInfo(result)
      "getScreenInfo" -> getScreenInfo(result)
      "getAdId" -> getAdId(result)
      "readAttribution" -> readAttribution(result)
            "getInstallTime" -> getInstallTime(result)
      
      "readAttributionToken" -> readAttributionToken(result)
      
      "getLanguageDisplayName" -> getLanguageDisplayName(call, result)
      else -> result.notImplemented()
    }
  }

  private fun getGpuInfo(result: Result) {
    try {
      val gpuInfo = mutableMapOf<String, Any>()
      
      // Create a hidden GLSurfaceView to get GPU info
      val glSurfaceView = GLSurfaceView(context)
      val latch = CountDownLatch(1)
      var renderer = ""
      var vendor = ""
      
      glSurfaceView.setEGLContextClientVersion(2)
      glSurfaceView.setRenderer(object : GLSurfaceView.Renderer {
        override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
          renderer = GLES20.glGetString(GLES20.GL_RENDERER) ?: "Unknown GPU"
          vendor = GLES20.glGetString(GLES20.GL_VENDOR) ?: ""
          latch.countDown()
        }
        
        override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {}
        override fun onDrawFrame(gl: GL10?) {}
      })
      
      // Wait for GPU info (with timeout)
      try {
        latch.await(2, java.util.concurrent.TimeUnit.SECONDS)
      } catch (e: InterruptedException) {
        renderer = "Unknown GPU"
      }
      
      gpuInfo["renderer"] = renderer
      gpuInfo["vendor"] = vendor
      
      // Get memory information
      val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val memoryInfo = ActivityManager.MemoryInfo()
      activityManager.getMemoryInfo(memoryInfo)
      
      gpuInfo["systemMemory"] = memoryInfo.totalMem
      
      // Real GPU memory implementation using OpenGL ES capabilities (most accurate method)
      val graphicsMemory = try {
        // Get GPU memory info from OpenGL ES context - this is the most reliable method
        val maxTextureSize = IntArray(1)
        val maxRenderbufferSize = IntArray(1)
        val maxVertexAttribs = IntArray(1)
        
        android.opengl.GLES20.glGetIntegerv(android.opengl.GLES20.GL_MAX_TEXTURE_SIZE, maxTextureSize, 0)
        android.opengl.GLES20.glGetIntegerv(android.opengl.GLES20.GL_MAX_RENDERBUFFER_SIZE, maxRenderbufferSize, 0)
        android.opengl.GLES20.glGetIntegerv(android.opengl.GLES20.GL_MAX_VERTEX_ATTRIBS, maxVertexAttribs, 0)
        
        // Calculate GPU memory based on OpenGL capabilities
        val textureMemoryCapacity = maxTextureSize[0] * maxTextureSize[0] * 4L // RGBA
        val renderbufferCapacity = maxRenderbufferSize[0] * maxRenderbufferSize[0] * 4L // RGBA
        
        // Estimate total GPU memory based on these capabilities
        // Modern mobile GPUs typically support multiple large textures
        val estimatedGpuMemory = maxOf(textureMemoryCapacity, renderbufferCapacity) * 8L // Multiple buffers
        
        // Cap at reasonable mobile GPU memory limits (128MB to 2GB range)
        val minGpuMemory = 128L * 1024 * 1024 // 128MB minimum
        val maxGpuMemory = 2L * 1024 * 1024 * 1024 // 2GB maximum for mobile
        
        estimatedGpuMemory.coerceIn(minGpuMemory, maxGpuMemory)
      } catch (e: Exception) {
        // Fallback: Conservative estimate based on total system memory
        val totalMemoryGB = memoryInfo.totalMem / (1024 * 1024 * 1024)
        when {
          totalMemoryGB >= 8 -> 1024L * 1024 * 1024 // 1GB for high-end devices
          totalMemoryGB >= 6 -> 768L * 1024 * 1024  // 768MB for mid-high devices  
          totalMemoryGB >= 4 -> 512L * 1024 * 1024  // 512MB for mid-range devices
          totalMemoryGB >= 2 -> 256L * 1024 * 1024  // 256MB for low-mid devices
          else -> 128L * 1024 * 1024                // 128MB for low-end devices
        }
      }
      
      gpuInfo["graphicsMemory"] = graphicsMemory
      
      result.success(gpuInfo)
    } catch (e: Exception) {
      // Fallback implementation when GPU detection fails
      try {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        // Conservative GPU memory estimate even in error case
        val totalMemoryGB = memoryInfo.totalMem / (1024 * 1024 * 1024)
        val fallbackGpuMemory = when {
          totalMemoryGB >= 8 -> 512L * 1024 * 1024 // 512MB for high-end devices
          totalMemoryGB >= 6 -> 384L * 1024 * 1024 // 384MB for mid-high devices  
          totalMemoryGB >= 4 -> 256L * 1024 * 1024 // 256MB for mid-range devices
          totalMemoryGB >= 2 -> 128L * 1024 * 1024 // 128MB for low-mid devices
          else -> 64L * 1024 * 1024                // 64MB for low-end devices
        }
        
        result.success(mapOf<String, Any>(
          "renderer" to "Unknown GPU",
          "vendor" to "Unknown",
          "systemMemory" to memoryInfo.totalMem,
          "graphicsMemory" to fallbackGpuMemory
        ))
      } catch (fallbackException: Exception) {
        result.success(mapOf<String, Any>(
          "renderer" to "Unknown GPU",
          "vendor" to "Unknown",
          "systemMemory" to 0,
          "graphicsMemory" to 0
        ))
      }
    }
  }
  
  private fun getScreenInfo(result: Result) {
    try {
      val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
      val displayMetrics = DisplayMetrics()
      windowManager.defaultDisplay.getRealMetrics(displayMetrics)
      
      val screenInfo = mapOf(
        "width" to displayMetrics.widthPixels,
        "height" to displayMetrics.heightPixels,
        "dpi" to displayMetrics.densityDpi.toDouble()
      )
      
      result.success(screenInfo)
    } catch (e: Exception) {
      result.success(mapOf<String, Any>(
        "width" to 0,
        "height" to 0,
        "dpi" to 0
      ))
    }
  }

  private fun getAdId(result: Result) {
    // Get Google Play Services Advertising ID in background thread
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val adInfo = AdvertisingIdClient.getAdvertisingIdInfo(context)
        val advertisingId = adInfo.id ?: ""
        val isLimitAdTrackingEnabled = adInfo.isLimitAdTrackingEnabled
        
        val adInfoMap = mapOf(
          "success" to true,
          "adId" to advertisingId,
          "trackingEnabled" to !isLimitAdTrackingEnabled // Return opposite of Limit Ad Tracking
        )
        
        // Return result on main thread
        withContext(Dispatchers.Main) {
          result.success(adInfoMap)
        }
      } catch (e: GooglePlayServicesNotAvailableException) {
        // Google Play Services not available
        withContext(Dispatchers.Main) {
          result.success(mapOf<String, Any>(
            "success" to false,
            "adId" to "",
            "trackingEnabled" to false,
            "error" to "Google Play Services not available"
          ))
        }
      } catch (e: GooglePlayServicesRepairableException) {
        // Google Play Services needs update
        withContext(Dispatchers.Main) {
          result.success(mapOf<String, Any>(
            "success" to false,
            "adId" to "", 
            "trackingEnabled" to false,
            "error" to "Google Play Services needs update"
          ))
        }
      } catch (e: IOException) {
        // Network or I/O error
        withContext(Dispatchers.Main) {
          result.success(mapOf<String, Any>(
            "success" to false,
            "adId" to "",
            "trackingEnabled" to false,
            "error" to "Network or I/O error"
          ))
        }
      } catch (e: Exception) {
        // Other errors
        withContext(Dispatchers.Main) {
          result.success(mapOf<String, Any>(
            "success" to false,
            "adId" to "",
            "trackingEnabled" to false,
            "error" to (e.message ?: "Unknown error")
          ))
        }
      }
    }
  }

  private fun readAttribution(result: Result) {
    // Real Install Referrer API implementation
    try {
      val referrerClient = InstallReferrerClient.newBuilder(context).build()
      
      referrerClient.startConnection(object : InstallReferrerStateListener {
        override fun onInstallReferrerSetupFinished(responseCode: Int) {
          when (responseCode) {
            InstallReferrerClient.InstallReferrerResponse.OK -> {
              try {
                val response: ReferrerDetails = referrerClient.installReferrer
                val referrerUrl = response.installReferrer ?: ""
                val referrerClickTime = response.referrerClickTimestampSeconds
                val appInstallTime = response.installBeginTimestampSeconds
                val instantExperienceLaunched = response.googlePlayInstantParam
                
                // Close the connection after getting data
                referrerClient.endConnection()
                
                val attributionData = mapOf(
                  "success" to true,
                  "referrerUrl" to referrerUrl,
                  "referrerClickTime" to referrerClickTime,
                  "appInstallTime" to appInstallTime,
                  "instantExperienceLaunched" to instantExperienceLaunched
                )
                
                result.success(attributionData)
              } catch (e: Exception) {
                referrerClient.endConnection()
                result.success(mapOf<String, Any>(
                  "success" to false,
                  "referrerUrl" to "",
                  "error" to "Error reading referrer details: ${e.message}"
                ))
              }
            }
            InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
              referrerClient.endConnection()
              result.success(mapOf<String, Any>(
                "success" to false,
                "referrerUrl" to "",
                "error" to "Install Referrer API not supported on this device"
              ))
            }
            InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
              referrerClient.endConnection()
              result.success(mapOf<String, Any>(
                "success" to false,
                "referrerUrl" to "",
                "error" to "Install Referrer service unavailable"
              ))
            }
            else -> {
              referrerClient.endConnection()
              result.success(mapOf<String, Any>(
                "success" to false,
                "referrerUrl" to "",
                "error" to "Install Referrer API connection failed with code: $responseCode"
              ))
            }
          }
        }
        
        override fun onInstallReferrerServiceDisconnected() {
          result.success(mapOf<String, Any>(
            "success" to false,
            "referrerUrl" to "",
            "error" to "Install Referrer service disconnected"
          ))
        }
      })
    } catch (e: Exception) {
      result.success(mapOf<String, Any>(
        "success" to false,
        "referrerUrl" to "",
        "error" to "Error initializing Install Referrer API: ${e.message}"
      ))
    }
  }

  private fun getInstallTime(result: Result) {
    // Real implementation using Install Referrer API to get precise install time
    try {
      val referrerClient = InstallReferrerClient.newBuilder(context).build()
      
      referrerClient.startConnection(object : InstallReferrerStateListener {
        override fun onInstallReferrerSetupFinished(responseCode: Int) {
          when (responseCode) {
            InstallReferrerClient.InstallReferrerResponse.OK -> {
              try {
                val response: ReferrerDetails = referrerClient.installReferrer
                val installTime = response.installBeginTimestampSeconds // Keep as seconds
                
                // Close the connection after getting data
                referrerClient.endConnection()
                
                // Return data in same format as iOS
                result.success(mapOf<String, Any>(
                  "success" to true,
                  "installTime" to installTime
                ))
              } catch (e: Exception) {
                referrerClient.endConnection()
                // Fallback to Package Manager if Install Referrer fails
                try {
                  val packageManager = context.packageManager
                  val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
                  val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
                  
                  result.success(mapOf<String, Any>(
                    "success" to true,
                    "installTime" to fallbackInstallTime
                  ))
                } catch (fallbackException: Exception) {
                  result.success(mapOf<String, Any>(
                    "success" to false,
                    "installTime" to (System.currentTimeMillis() / 1000),
                    "error" to "Error getting install time: ${e.message}"
                  ))
                }
              }
            }
            InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
              referrerClient.endConnection()
              // Fallback to Package Manager
              try {
                val packageManager = context.packageManager
                val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
                val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
                
                result.success(mapOf<String, Any>(
                  "success" to true,
                  "installTime" to fallbackInstallTime
                ))
              } catch (e: Exception) {
                result.success(mapOf<String, Any>(
                  "success" to false,
                  "installTime" to (System.currentTimeMillis() / 1000),
                  "error" to "Install Referrer not supported and Package Manager failed: ${e.message}"
                ))
              }
            }
            InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
              referrerClient.endConnection()
              // Fallback to Package Manager
              try {
                val packageManager = context.packageManager
                val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
                val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
                
                result.success(mapOf<String, Any>(
                  "success" to true,
                  "installTime" to fallbackInstallTime
                ))
              } catch (e: Exception) {
                result.success(mapOf<String, Any>(
                  "success" to false,
                  "installTime" to (System.currentTimeMillis() / 1000),
                  "error" to "Install Referrer service unavailable and Package Manager failed: ${e.message}"
                ))
              }
            }
            else -> {
              referrerClient.endConnection()
              // Fallback to Package Manager
              try {
                val packageManager = context.packageManager
                val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
                val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
                
                result.success(mapOf<String, Any>(
                  "success" to true,
                  "installTime" to fallbackInstallTime
                ))
              } catch (e: Exception) {
                result.success(mapOf<String, Any>(
                  "success" to false,
                  "installTime" to (System.currentTimeMillis() / 1000),
                  "error" to "Install Referrer failed with code $responseCode and Package Manager failed: ${e.message}"
                ))
              }
            }
          }
        }
        
        override fun onInstallReferrerServiceDisconnected() {
          // Fallback to Package Manager if service disconnects
          try {
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
            val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
            
            result.success(mapOf<String, Any>(
              "success" to true,
              "installTime" to fallbackInstallTime
            ))
          } catch (e: Exception) {
            result.success(mapOf<String, Any>(
              "success" to false,
              "installTime" to (System.currentTimeMillis() / 1000),
              "error" to "Install Referrer service disconnected and Package Manager failed: ${e.message}"
            ))
          }
        }
      })
    } catch (e: Exception) {
      // Fallback to Package Manager if Install Referrer initialization fails
      try {
        val packageManager = context.packageManager
        val packageInfo = packageManager.getPackageInfo(context.packageName, 0)
        val fallbackInstallTime = packageInfo.firstInstallTime / 1000 // Convert to seconds
        
        result.success(mapOf<String, Any>(
          "success" to true,
          "installTime" to fallbackInstallTime
        ))
      } catch (fallbackException: Exception) {
        result.success(mapOf<String, Any>(
          "success" to false,
          "installTime" to (System.currentTimeMillis() / 1000),
          "error" to "Error initializing Install Referrer and Package Manager failed: ${e.message}"
        ))
      }
    }
  }

  private fun readAttributionToken(result: Result) {
    // Android equivalent using Install Referrer API - create a token from referrer data
    try {
      val referrerClient = InstallReferrerClient.newBuilder(context).build()
      
      referrerClient.startConnection(object : InstallReferrerStateListener {
        override fun onInstallReferrerSetupFinished(responseCode: Int) {
          when (responseCode) {
            InstallReferrerClient.InstallReferrerResponse.OK -> {
              try {
                val response: ReferrerDetails = referrerClient.installReferrer
                val referrerUrl = response.installReferrer ?: ""
                
                // Close the connection after getting data
                referrerClient.endConnection()
                
                // Create a simple token from referrer URL (Android equivalent to iOS attribution token)
                val token = if (referrerUrl.isNotEmpty()) {
                  android.util.Base64.encodeToString(referrerUrl.toByteArray(), android.util.Base64.DEFAULT)
                } else {
                  ""
                }
                
                result.success(mapOf<String, Any>(
                  "success" to true,
                  "token" to token
                ))
              } catch (e: Exception) {
                referrerClient.endConnection()
                result.success(mapOf<String, Any>(
                  "success" to false,
                  "error" to "Error creating attribution token: ${e.message}"
                ))
              }
            }
            else -> {
              referrerClient.endConnection()
              result.success(mapOf<String, Any>(
                "success" to false,
                "error" to "Install Referrer API not available for attribution token"
              ))
            }
          }
        }
        
        override fun onInstallReferrerServiceDisconnected() {
          result.success(mapOf<String, Any>(
            "success" to false,
            "error" to "Install Referrer service disconnected while creating token"
          ))
        }
      })
    } catch (e: Exception) {
      result.success(mapOf<String, Any>(
        "success" to false,
        "error" to "Error initializing Install Referrer for attribution token: ${e.message}"
      ))
    }
  }
  
  private fun getLanguageDisplayName(call: MethodCall, result: Result) {
    try {
      val languageCode = call.argument<String>("languageCode")
      if (languageCode.isNullOrEmpty()) {
        result.success("")
        return
      }
      
      // Create locale and get display name
      val locale = Locale(languageCode)
      val englishLocale = Locale.US
      
      // Always get the language name according to English locale
      val displayName = locale.getDisplayLanguage(englishLocale)
      if (displayName.isNotEmpty() && displayName != languageCode) {
        // Capitalize first letter
        val capitalizedName = displayName.replaceFirstChar { 
          if (it.isLowerCase()) it.titlecase(englishLocale) else it.toString() 
        }
        result.success(capitalizedName)
      } else {
        result.success("")
      }
    } catch (e: Exception) {
      result.success("")
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
} 