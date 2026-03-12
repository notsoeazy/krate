package com.notsoeazy.krate

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.notsoeazy.krate/file_utils"
    private val PICK_FILES_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRealPath" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val path = getRealPathFromURI(this, Uri.parse(uriString))
                        result.success(path)
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is null", null)
                    }
                }
                "pickFiles" -> {
                    val allowedExtensions = call.argument<List<String>>("allowedExtensions")
                    val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                    pendingResult = result
                    startFilePicker(allowedExtensions, allowMultiple)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startFilePicker(allowedExtensions: List<String>?, allowMultiple: Boolean) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
            
            // Filter by mime types if extensions are provided
            if (allowedExtensions != null && allowedExtensions.isNotEmpty()) {
                val mimeTypes = allowedExtensions.mapNotNull { ext ->
                    android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
                }.toTypedArray()
                if (mimeTypes.isNotEmpty()) {
                    putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                }
            }
        }
        startActivityForResult(intent, PICK_FILES_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_FILES_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val resultList = mutableListOf<Map<String, String>>()
                
                // Handle multiple selection
                if (data.clipData != null) {
                    val count = data.clipData!!.itemCount
                    for (i in 0 until count) {
                        val uri = data.clipData!!.getItemAt(i).uri
                        getFileInfo(uri)?.let { resultList.add(it) }
                    }
                } else if (data.data != null) {
                    // Handle single selection
                    val uri = data.data!!
                    getFileInfo(uri)?.let { resultList.add(it) }
                }
                
                pendingResult?.success(resultList)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun getFileInfo(uri: Uri): Map<String, String>? {
        val resolver = contentResolver
        val cursor: Cursor? = resolver.query(uri, null, null, null, null)
        
        return cursor?.use {
            if (it.moveToFirst()) {
                val name = it.getString(it.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                val size = it.getLong(it.getColumnIndexOrThrow(OpenableColumns.SIZE)).toString()
                
                // Persist permission to access this URI across reboots/app restarts if needed
                try {
                    val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    resolver.takePersistableUriPermission(uri, takeFlags)
                } catch (e: Exception) {
                    // This might fail if the provider doesn't support persistable permissions
                }

                val realPath = getRealPathFromURI(this, uri) ?: ""
                
                mapOf(
                    "name" to name,
                    "uri" to uri.toString(),
                    "path" to realPath,
                    "size" to size
                )
            } else null
        }
    }

    private fun getRealPathFromURI(context: Context, uri: Uri): String? {
        // DocumentProvider
        if (DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).toTypedArray()
                val type = split[0]
                if ("primary".equals(type, ignoreCase = true)) {
                    return "/storage/emulated/0/" + split[1]
                }
            } else if (isDownloadsDocument(uri)) {
                // DownloadsProvider
                val id = DocumentsContract.getDocumentId(uri)
                if (id.startsWith("raw:")) {
                    return id.substring(4)
                }
            } else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).toTypedArray()
                val type = split[0]
                var contentUri: Uri? = null
                if ("image" == type) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                } else if ("video" == type) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else if ("audio" == type) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }
                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return getDataColumn(context, uri, null, null)
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        return null
    }

    private fun getDataColumn(context: Context, uri: Uri?, selection: String?, selectionArgs: Array<String>?): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)
        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndex(column)
                if (columnIndex != -1) {
                    return cursor.getString(columnIndex)
                }
            }
        } catch (e: Exception) {
            // Log error
        } finally {
            cursor?.close()
        }
        return null
    }

    private fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    private fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    private fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }
}
