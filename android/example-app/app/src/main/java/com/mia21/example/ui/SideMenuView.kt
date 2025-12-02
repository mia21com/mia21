package com.mia21.example.ui

/**
 * SideMenuView.kt
 * Sidebar menu composable that slides in from the left.
 * Displays space/bot selection, environment switcher, conversation history,
 * and new chat button. Supports swipe-to-delete for conversations.
 */

import android.util.Log
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DividerDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.mia21.example.R
import com.mia21.example.theme.MiaColors
import com.mia21.example.viewmodels.SideMenuViewModel
import com.mia21.models.Bot
import com.mia21.models.ConversationSummary
import com.mia21.models.Mia21Environment
import com.mia21.models.Space

@Composable
fun SideMenuView(
    modifier: Modifier = Modifier,
    isVisible: Boolean,
    viewModel: SideMenuViewModel,
    onSpaceChanged: (Space, Bot?) -> Unit,
    onBotChanged: (Bot) -> Unit,
    onNewChat: () -> Unit,
    onSelectChat: (String) -> Unit,
    onDeleteCurrentChat: (() -> Unit)? = null,
    currentConversationId: String? = null,
    onEnvironmentChanged: ((Mia21Environment) -> Unit)? = null,
    currentEnvironment: Mia21Environment? = null,
) {
    val context = LocalContext.current
    val spaces by viewModel.spaces.collectAsState()
    val bots by viewModel.bots.collectAsState()
    val conversations by viewModel.conversations.collectAsState()
    val selectedSpace by viewModel.selectedSpace.collectAsState()
    val selectedBot by viewModel.selectedBot.collectAsState()
    val selectedConversationId by viewModel.selectedConversationId.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()

    var showingSpaceSelector by remember { mutableStateOf(false) }
    var showingBotSelector by remember { mutableStateOf(false) }
    var showingEnvironmentSelector by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.loadInitialDataIfNeeded()
    }

    val animatedOffset by animateFloatAsState(
        targetValue = if (isVisible) 0f else -280f,
        animationSpec = tween(
            durationMillis = if (isVisible) 300 else 250,
            easing = if (isVisible) {
                FastOutSlowInEasing
            } else {
                FastOutLinearInEasing
            }
        ),
        label = "sideMenuAnimation"
    )

    Box(
        modifier = modifier
            .width(280.dp)
            .fillMaxHeight()
            .background(MiaColors.SidebarBackground)
            .graphicsLayer {
                translationX = animatedOffset.dp.toPx()
            }
            .zIndex(2f)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = 12.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // New Chat button
            Button(
                onClick = {
                    viewModel.clearConversationSelection()
                    onNewChat()
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                contentPadding = PaddingValues(0.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(44.dp)
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    MiaColors.GradientStart,
                                    MiaColors.GradientEnd
                                )
                            ),
                            shape = RoundedCornerShape(4.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = null,
                            tint = MiaColors.OnPrimary,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = stringResource(R.string.new_chat),
                            color = MiaColors.OnPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Loading indicator
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                }
            }

            // Error message
            errorMessage?.let { error ->
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .clickable {
                            viewModel.clearError()
                        },
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(12.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            // RECENTS header
            Text(
                text = stringResource(R.string.recents),
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 20.dp)
            )

            // Conversation list
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(conversations) { conversation ->
                    ConversationItem(
                        conversation = conversation,
                        spaces = spaces,
                        bots = bots,
                        isSelected = conversation.id == selectedConversationId,
                        onSelect = {
                            viewModel.selectConversation(conversation.id)
                            onSelectChat(conversation.id)
                        },
                        onDelete = {
                            val isCurrentConversation = conversation.id == currentConversationId

                            if (isCurrentConversation) {
                                onDeleteCurrentChat?.invoke()
                            }

                            viewModel.deleteConversationAsync(conversation.id)
                        }
                    )
                }
            }

            HorizontalDivider(
                modifier = Modifier.padding(vertical = 12.dp),
                thickness = DividerDefaults.Thickness,
                color = DividerDefaults.color
            )

            // Space selector
            Box(modifier = Modifier.fillMaxWidth()) {
                Button(
                    onClick = { showingSpaceSelector = !showingSpaceSelector },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MiaColors.CardBackground
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .background(
                                        brush = Brush.horizontalGradient(
                                            colors = listOf(
                                                MiaColors.GradientStart,
                                                MiaColors.GradientEnd
                                            )
                                        ),
                                        shape = CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = viewModel.spaceAvatarLetter,
                                    color = MiaColors.OnPrimary,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = viewModel.getSpaceDisplayName(context),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }

                DropdownMenu(
                    expanded = showingSpaceSelector,
                    onDismissRequest = { showingSpaceSelector = false },
                    modifier = Modifier.width(280.dp)
                ) {
                    spaces.forEach { space ->
                        val isSelected = space.spaceId == selectedSpace?.spaceId
                        DropdownMenuItem(
                            text = {
                                Text(
                                    text = if (isSelected) "${space.name} ✓" else space.name
                                )
                            },
                            onClick = {
                                // Don't allow selecting the same space
                                if (!isSelected) {
                                    viewModel.selectSpace(space)
                                    onSpaceChanged(space, selectedBot)
                                }
                                showingSpaceSelector = false
                            },
                            enabled = !isSelected
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Bot selector
            Box(modifier = Modifier.fillMaxWidth()) {
                Button(
                    onClick = { showingBotSelector = !showingBotSelector },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MiaColors.CardBackground
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .background(
                                        brush = Brush.horizontalGradient(
                                            colors = listOf(
                                                MiaColors.GradientStart,
                                                MiaColors.GradientEnd
                                            )
                                        ),
                                        shape = CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "✨",
                                    fontSize = 20.sp
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = viewModel.getBotDisplayName(context),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }

                DropdownMenu(
                    expanded = showingBotSelector,
                    onDismissRequest = { showingBotSelector = false },
                    modifier = Modifier.width(280.dp)
                ) {
                    bots.forEach { bot ->
                        val isSelected = bot.botId == selectedBot?.botId
                        DropdownMenuItem(
                            text = {
                                Text(
                                    text = if (isSelected) "${bot.name} ✓" else bot.name
                                )
                            },
                            onClick = {
                                // Don't allow selecting the same bot
                                if (!isSelected) {
                                    viewModel.selectBot(bot)
                                    onBotChanged(bot)
                                }
                                showingBotSelector = false
                            },
                            enabled = !isSelected
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Environment selector
            if (onEnvironmentChanged != null && currentEnvironment != null) {
                HorizontalDivider(
                    modifier = Modifier.padding(vertical = 8.dp),
                    thickness = DividerDefaults.Thickness,
                    color = DividerDefaults.color
                )

                Box(modifier = Modifier.fillMaxWidth()) {
                    Button(
                        onClick = { showingEnvironmentSelector = !showingEnvironmentSelector },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 0.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MiaColors.CardBackground
                        ),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = currentEnvironment.environmentName,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface,
                                maxLines = 1
                            )
                            Icon(
                                imageVector = Icons.Default.ArrowDropDown,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    DropdownMenu(
                        expanded = showingEnvironmentSelector,
                        onDismissRequest = { showingEnvironmentSelector = false },
                        modifier = Modifier.width(280.dp)
                    ) {
                        DropdownMenuItem(
                            text = {
                                Text(
                                    text = if (currentEnvironment == Mia21Environment.PRODUCTION) {
                                        stringResource(R.string.environment_production_selected)
                                    } else {
                                        stringResource(R.string.environment_production)
                                    }
                                )
                            },
                            onClick = {
                                onEnvironmentChanged(Mia21Environment.PRODUCTION)
                                showingEnvironmentSelector = false
                            }
                        )
                        DropdownMenuItem(
                            text = {
                                Text(
                                    text = if (currentEnvironment == Mia21Environment.STAGING) {
                                        stringResource(R.string.environment_staging_selected)
                                    } else {
                                        stringResource(R.string.environment_staging)
                                    }
                                )
                            },
                            onClick = {
                                onEnvironmentChanged(Mia21Environment.STAGING)
                                showingEnvironmentSelector = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
        }
    }


}

@Composable
private fun ConversationItem(
    conversation: ConversationSummary,
    spaces: List<Space>,
    bots: List<Bot>,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onDelete: () -> Unit
) {
    val density = LocalDensity.current
    val deleteButtonWidth = 70.dp
    val deleteButtonWidthPx = with(density) { deleteButtonWidth.toPx() }

    var swipeOffset by remember(isSelected) { mutableFloatStateOf(0f) }
    val spaceName = spaces.firstOrNull { it.spaceId == conversation.spaceId }?.name
    val botName = bots.firstOrNull { it.botId == conversation.botId }?.name

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .background(MiaColors.ConversationItemBackground, RoundedCornerShape(8.dp))
            .clip(RoundedCornerShape(8.dp))
    ) {
        // Delete button
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .width(deleteButtonWidth)
                .align(Alignment.CenterEnd)
                .background(
                    color = MiaColors.DeleteButton,
                    shape = RoundedCornerShape(8.dp)
                )
                .zIndex(0f)

                .clickable(
                    onClick = {
                        onDelete()
                        swipeOffset = 0f
                    },
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() }
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Delete,
                contentDescription = stringResource(R.string.content_description_delete),
                tint = MiaColors.OnPrimary,
                modifier = Modifier.size(24.dp)
            )
        }

        // Conversation item
        val animatedOffset by animateFloatAsState(
            targetValue = swipeOffset,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            ),
            label = "swipeAnimation"
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight()
                .graphicsLayer {
                    translationX = animatedOffset
                }
                .pointerInput(conversation.id) {
                    var dragStarted = false
                    detectHorizontalDragGestures(
                        onDragStart = { dragStarted = true },
                        onDragEnd = {
                            val threshold = -deleteButtonWidthPx * 0.6f
                            swipeOffset = if (swipeOffset < threshold) {
                                -deleteButtonWidthPx
                            } else {
                                0f
                            }
                            dragStarted = false
                        }
                    ) { change, dragAmount ->
                        dragStarted = true
                        if (dragAmount < 0 || swipeOffset < 0) {
                            swipeOffset =
                                (swipeOffset + dragAmount).coerceIn(-deleteButtonWidthPx, 0f)
                        }
                    }
                }
                .clickable {
                    if (swipeOffset == 0f) {
                        onSelect()
                    } else {
                        swipeOffset = 0f
                    }
                }
                .background(
                    color = if (isSelected) {
                        MiaColors.Second
                    } else {
                        MiaColors.ConversationItemBackground
                    },
                    shape = RoundedCornerShape(8.dp)
                )
                .padding(horizontal = 12.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = conversation.displayTitle(spaceName, botName),
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

