using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/chat")]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly IChatService _chatService;

        public ChatController(IChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpPost("conversations/get-or-create")]
        public async Task<ActionResult<ChatConversationResponse?>> GetConversation([FromBody] ChatConversationGetOrCreateRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var convo = await _chatService.GetConversationAsync(request.RestaurantId, userId);
                // Always return 200, even if conversation is null (not created yet)
                return Ok(convo ?? (object?)null);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("restaurants/{restaurantId:int}/messages/first")]
        public async Task<ActionResult<ChatMessageResponse>> SendFirstMessage(int restaurantId, [FromBody] ChatMessageCreateRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var msg = await _chatService.SendFirstMessageAsync(restaurantId, userId, request.MessageText);
                return Ok(msg);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        /// <summary>
        /// Customer-side conversations (mobile app): returns conversations for the current user.
        /// </summary>
        [HttpGet("conversations")]
        public async Task<ActionResult<List<ChatConversationResponse>>> GetMyConversations()
        {
            var userId = GetCurrentUserId();
            var list = await _chatService.GetMyConversationsAsync(userId);
            return Ok(list);
        }

        /// <summary>
        /// Restaurant-side conversations (desktop): returns conversations for a specific restaurant, only for its owner.
        /// </summary>
        [HttpGet("restaurants/{restaurantId:int}/conversations")]
        public async Task<ActionResult<List<ChatConversationResponse>>> GetRestaurantConversations(int restaurantId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var list = await _chatService.GetRestaurantConversationsAsync(restaurantId, userId);
                return Ok(list);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpGet("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<List<ChatMessageResponse>>> GetMessages(
            int conversationId,
            [FromQuery] int? afterId = null,
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var userId = GetCurrentUserId();
                var list = await _chatService.GetMessagesAsync(conversationId, userId, afterId, page, pageSize);
                return Ok(list);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpPost("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<ChatMessageResponse>> SendMessage(int conversationId, [FromBody] ChatMessageCreateRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var msg = await _chatService.SendMessageAsync(conversationId, userId, request.MessageText);
                return Ok(msg);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("conversations/{conversationId:int}/read")]
        public async Task<ActionResult<object>> MarkRead(int conversationId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var updated = await _chatService.MarkConversationReadAsync(conversationId, userId);
                return Ok(new { updated });
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        [HttpDelete("conversations/{conversationId:int}")]
        public async Task<ActionResult> DeleteConversation(int conversationId)
        {
            try
            {
                var userId = GetCurrentUserId();
                await _chatService.DeleteConversationAsync(conversationId, userId);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
        }

        private int GetCurrentUserId()
        {
            var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(idStr) || !int.TryParse(idStr, out var id))
                throw new ArgumentException("Invalid user identity.");
            return id;
        }
    }
}

