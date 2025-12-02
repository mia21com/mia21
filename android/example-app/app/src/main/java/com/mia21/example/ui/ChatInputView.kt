package com.mia21.example.ui

/**
 * ChatInputView.kt
 * Composable for the chat input field and action buttons.
 * Handles text input, send button, microphone recording button,
 * and hands-free mode button with visual state indicators.
 */

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material3.DividerDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.mia21.example.R
import com.mia21.example.theme.MiaColors
import kotlinx.coroutines.delay

@Composable
fun ChatInputView(
    modifier: Modifier = Modifier,
    inputText: String,
    onInputTextChange: (String) -> Unit,
    isLoading: Boolean,
    canSend: Boolean,
    isHandsFreeModeEnabled: Boolean,
    isHandsFreeListening: Boolean = false,
    isHandsFreeVoiceActive: Boolean = false,
    onSend: () -> Unit,
    onHandsFreeTapped: () -> Unit,
    onRecordAudio: (() -> Unit)? = null,
    isRecording: Boolean = false,
    isTranscribing: Boolean = false,
    focusRequester: FocusRequester? = null,
    onFocusChanged: ((Boolean) -> Unit)? = null
) {
    val hasText = inputText.trim().isNotEmpty()
    val localFocusRequester = remember { FocusRequester() }
    val actualFocusRequester = focusRequester ?: localFocusRequester

    var textFieldValue by remember(inputText) {
        mutableStateOf(TextFieldValue(inputText, TextRange(inputText.length)))
    }

    LaunchedEffect(inputText) {
        textFieldValue = TextFieldValue(inputText, TextRange(inputText.length))
    }

    LaunchedEffect(Unit) {
        if (!isHandsFreeModeEnabled && !isLoading) {
            delay(300)
            actualFocusRequester.requestFocus()
            delay(50)
            textFieldValue = TextFieldValue(inputText, TextRange(inputText.length))
        }
    }

    LaunchedEffect(isHandsFreeModeEnabled, isLoading) {
        if (!isHandsFreeModeEnabled && !isLoading) {
            delay(100)
            actualFocusRequester.requestFocus()
            delay(50)
            textFieldValue = TextFieldValue(inputText, TextRange(inputText.length))
        }
    }

    Column(modifier = modifier) {
        HorizontalDivider(
            modifier = Modifier.height(0.5.dp),
            thickness = DividerDefaults.Thickness,
            color = DividerDefaults.color
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp)
                    .background(
                        color = MiaColors.SidebarBackground,
                        shape = RoundedCornerShape(32.dp)
                    ),
                contentAlignment = Alignment.CenterStart
            ) {
                // Placeholder text with loader
                if (inputText.isEmpty()) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        when {
                            isRecording -> {
                                CircleLoader(size = 12.dp)
                                Text(
                                    text = stringResource(R.string.input_placeholder_listening),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }

                            isTranscribing -> {
                                CircleLoader(size = 12.dp)
                                Text(
                                    text = stringResource(R.string.input_placeholder_transcribing),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }

                            else -> {
                                Text(
                                    text = stringResource(R.string.input_placeholder_message),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }
                        }
                    }
                }

                BasicTextField(
                    value = textFieldValue,
                    onValueChange = { newValue ->
                        textFieldValue = newValue
                        onInputTextChange(newValue.text)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp)
                        .focusRequester(actualFocusRequester)
                        .onFocusChanged { focusState ->
                            onFocusChanged?.invoke(focusState.isFocused)
                        },
                    enabled = !isHandsFreeModeEnabled && !isRecording && !isTranscribing,
                    textStyle = MaterialTheme.typography.bodyLarge.copy(
                        color = MaterialTheme.colorScheme.onSurface
                    ),
                    maxLines = 3,
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Send
                    ),
                    keyboardActions = KeyboardActions(
                        onSend = {
                            if (inputText.trim().isNotEmpty() && !isLoading) {
                                onSend()
                            }
                        }
                    ),
                    singleLine = false
                )
            }

            // Mic/Stop button
            if (!hasText) {
                Spacer(modifier = Modifier.width(14.dp))

                Box(
                    modifier = Modifier
                        .size(if (isRecording) 40.dp else 32.dp)
                        .background(
                            color = if (isRecording) {
                                MiaColors.Recording
                            } else {
                                MiaColors.SidebarBackground
                            },
                            shape = CircleShape
                        )
                        .clickable(
                            enabled = !isHandsFreeModeEnabled && !isLoading && !isTranscribing,
                            onClick = { onRecordAudio?.invoke() },
                            indication = null,
                            interactionSource = remember { MutableInteractionSource() }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (isRecording) {
                        Box(
                            modifier = Modifier
                                .size(16.dp)
                                .background(
                                    color = MiaColors.OnPrimary,
                                    shape = RoundedCornerShape(2.dp)
                                )
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Mic,
                            contentDescription = stringResource(R.string.content_description_record),
                            tint = if (!isHandsFreeModeEnabled && !isLoading) {
                                MaterialTheme.colorScheme.onSurface
                            } else {
                                MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                            },
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }

            // Send button
            if (hasText) {
                Spacer(modifier = Modifier.width(16.dp))

                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = if (canSend && !isHandsFreeModeEnabled) {
                                    listOf(
                                        MiaColors.GradientStart,
                                        MiaColors.GradientEnd
                                    )
                                } else {
                                    listOf(
                                        MiaColors.GradientStart.copy(alpha = 0.5f),
                                        MiaColors.GradientEnd.copy(alpha = 0.5f)
                                    )
                                }
                            ),
                            shape = CircleShape
                        )
                        .clickable(
                            enabled = canSend && !isHandsFreeModeEnabled,
                            onClick = onSend,
                            indication = null,
                            interactionSource = remember { MutableInteractionSource() }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowUpward,
                        contentDescription = "Send",
                        tint = if (canSend && !isHandsFreeModeEnabled) {
                            MiaColors.OnPrimary
                        } else {
                            MiaColors.OnPrimary.copy(alpha = 0.5f)
                        },
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            // Hands-free button - hide when user is typing or voice recording
            if (!hasText && !isRecording && !isTranscribing) {
                Spacer(modifier = Modifier.width(8.dp))

                val handsFreeInteractionSource = remember { MutableInteractionSource() }
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(
                            color = when {
                                isHandsFreeVoiceActive -> MiaColors.Recording
                                isHandsFreeListening -> MiaColors.HandsFreeEnabled
                                isHandsFreeModeEnabled -> MiaColors.HandsFreeEnabled
                                else -> MiaColors.SidebarBackground
                            },
                            shape = CircleShape
                        )
                        .clickable(
                            enabled = !isLoading,
                            onClick = onHandsFreeTapped,
                            indication = null,
                            interactionSource = handsFreeInteractionSource
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (isHandsFreeVoiceActive) {
                        // Show pulsing indicator when voice is active
                        Box(
                            modifier = Modifier.size(12.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .background(
                                        color = MiaColors.OnPrimary,
                                        shape = CircleShape
                                    )
                            )
                        }
                    } else {
                        Icon(
                            imageVector = Icons.Default.Waves,
                            contentDescription = stringResource(R.string.content_description_hands_free),
                            tint = if (isHandsFreeListening || isHandsFreeModeEnabled) {
                                MiaColors.OnPrimary
                            } else {
                                MaterialTheme.colorScheme.onSurface
                            },
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun CircleLoader(size: Dp) {
    val infiniteTransition = rememberInfiniteTransition(label = "loader")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    Canvas(modifier = Modifier.size(size)) {
        val strokeWidth = size.toPx() * 0.15f
        val radius = (size.toPx() - strokeWidth) / 2f
        val centerX = size.toPx() / 2f
        val centerY = size.toPx() / 2f

        drawArc(
            color = MiaColors.OnPrimary,
            startAngle = rotation - 90f,
            sweepAngle = 270f,
            useCenter = false,
            topLeft = Offset(centerX - radius, centerY - radius),
            size = Size(radius * 2, radius * 2),
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )
    }
}

