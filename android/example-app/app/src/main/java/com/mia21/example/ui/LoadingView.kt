package com.mia21.example.ui

/**
 * LoadingView.kt
 * Splash/loading screen composable.
 * Displays animated logo while loading spaces and bots from the API.
 * Shows error message with retry button if loading fails.
 */

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.mia21.Mia21Client
import com.mia21.example.R
import com.mia21.example.viewmodels.LoadingResult
import com.mia21.example.viewmodels.LoadingViewModel
import kotlinx.coroutines.delay

@Composable
fun LoadingView(
    client: Mia21Client,
    viewModel: LoadingViewModel? = null,
    onLoadComplete: (LoadingResult) -> Unit
) {
    val viewModelInstance: LoadingViewModel = viewModel ?: androidx.lifecycle.viewmodel.compose.viewModel { LoadingViewModel(client) }
    val isLoading by viewModelInstance.isLoading.collectAsState()
    val errorMessage by viewModelInstance.errorMessage.collectAsState()
    val result by viewModelInstance.result.collectAsState()

    var logoScale by remember { mutableFloatStateOf(0.5f) }
    var logoOpacity by remember { mutableFloatStateOf(0f) }
    var isBreathing by remember { mutableStateOf(false) }

    val infiniteTransition = rememberInfiniteTransition(label = "breathing")
    val breathingScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "breathing"
    )

    LaunchedEffect(Unit) {
        logoScale = 1f
        logoOpacity = 1f

        delay(800)
        isBreathing = true
    }

    var hasProceeded by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModelInstance.loadData()
    }

    LaunchedEffect(Unit) {
        delay(10_000L)
        if (!hasProceeded) {
            hasProceeded = true
            val currentResult = result ?: LoadingResult(
                spaces = emptyList(),
                selectedSpace = null,
                bots = emptyList(),
                selectedBot = null
            )
            onLoadComplete(currentResult)
        }
    }

    LaunchedEffect(result) {
        result?.let {
            if (!hasProceeded) {
                hasProceeded = true
                delay(200)
                onLoadComplete(it)
            }
        }
    }

    LaunchedEffect(errorMessage, isLoading) {
        if (errorMessage != null && !isLoading && !hasProceeded) {
            hasProceeded = true
            val currentResult = result ?: LoadingResult(
                spaces = emptyList(),
                selectedSpace = null,
                bots = emptyList(),
                selectedBot = null
            )
            onLoadComplete(currentResult)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(40.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .graphicsLayer {
                        scaleX = logoScale * if (isBreathing) breathingScale else 1f
                        scaleY = logoScale * if (isBreathing) breathingScale else 1f
                        alpha = logoOpacity
                    },
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.mia_loader_logo),
                    contentDescription = stringResource(R.string.content_description_mia_logo),
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Fit
                )
            }

            // Show loading indicator or error message
            if (errorMessage != null) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = errorMessage ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error
                    )
                    Button(
                        onClick = { viewModelInstance.loadData() }
                    ) {
                        Text(stringResource(R.string.button_retry))
                    }
                }
            }
        }
    }
}

