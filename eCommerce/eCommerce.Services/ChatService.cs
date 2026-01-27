using eCommerce.Model.Responses;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class ChatService : IChatService
    {
        private readonly eCommerceDbContext _context;

        public ChatService(eCommerceDbContext context)
        {
            _context = context;
        }

        public async Task<ChatConversationResponse?> GetConversationAsync(int restaurantId, int customerUserId)
        {
            var restaurant = await _context.Restaurants
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.Id == restaurantId);

            if (restaurant == null)
                throw new KeyNotFoundException("Restaurant not found.");

            var existing = await _context.ChatConversations
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.RestaurantId == restaurantId && c.UserId == customerUserId);

            if (existing == null)
                return null;

            return await MapConversationForCallerAsync(existing.Id, customerUserId);
        }

        public async Task<List<ChatConversationResponse>> GetMyConversationsAsync(int customerUserId)
        {
            var list = await _context.ChatConversations
                .AsNoTracking()
                .Where(c => c.UserId == customerUserId)
                .OrderByDescending(c => c.LastMessageAt)
                .Select(c => new ChatConversationResponse
                {
                    Id = c.Id,
                    UserId = c.UserId,
                    UserName = c.User.FirstName + " " + c.User.LastName,
                    RestaurantId = c.RestaurantId,
                    RestaurantName = c.Restaurant.Name,
                    StartedAt = c.StartedAt,
                    LastMessageAt = c.LastMessageAt,
                    Status = c.Status,
                    LastMessageText = c.Messages
                        .OrderByDescending(m => m.SentAt)
                        .Select(m => m.MessageText)
                        .FirstOrDefault(),
                    UnreadCount = c.Messages.Count(m => !m.IsRead && m.SenderId != customerUserId)
                })
                .ToListAsync();

            return list;
        }

        public async Task<List<ChatConversationResponse>> GetRestaurantConversationsAsync(int restaurantId, int ownerUserId)
        {
            // Ownership check: the caller must own this restaurant.
            var owns = await _context.Restaurants
                .AsNoTracking()
                .AnyAsync(r => r.Id == restaurantId && r.OwnerId == ownerUserId);

            if (!owns)
                throw new UnauthorizedAccessException("You do not have access to this restaurant's conversations.");

            var list = await _context.ChatConversations
                .AsNoTracking()
                .Where(c => c.RestaurantId == restaurantId)
                .OrderByDescending(c => c.LastMessageAt)
                .Select(c => new ChatConversationResponse
                {
                    Id = c.Id,
                    UserId = c.UserId,
                    UserName = c.User.FirstName + " " + c.User.LastName,
                    RestaurantId = c.RestaurantId,
                    RestaurantName = c.Restaurant.Name,
                    StartedAt = c.StartedAt,
                    LastMessageAt = c.LastMessageAt,
                    Status = c.Status,
                    LastMessageText = c.Messages
                        .OrderByDescending(m => m.SentAt)
                        .Select(m => m.MessageText)
                        .FirstOrDefault(),
                    // For restaurant side, "unread" means unread customer messages
                    UnreadCount = c.Messages.Count(m => !m.IsRead && m.SenderId == c.UserId)
                })
                .ToListAsync();

            return list;
        }

        public async Task<List<ChatMessageResponse>> GetMessagesAsync(int conversationId, int callerUserId, int? afterId = null, int page = 0, int pageSize = 50)
        {
            var conversation = await GetConversationForCallerAsync(conversationId, callerUserId);

            IQueryable<ChatMessage> query = _context.ChatMessages
                .AsNoTracking()
                .Where(m => m.ConversationId == conversationId);

            if (afterId.HasValue)
            {
                query = query.Where(m => m.Id > afterId.Value)
                             .OrderBy(m => m.Id);
            }
            else
            {
                // Chat-style paging: page=0 gives latest pageSize messages
                query = query.OrderByDescending(m => m.Id)
                             .Skip(page * pageSize)
                             .Take(pageSize)
                             .OrderBy(m => m.Id);
            }

            var messages = await query
                .Select(m => new ChatMessageResponse
                {
                    Id = m.Id,
                    ConversationId = m.ConversationId,
                    SenderId = m.SenderId,
                    SenderName = m.Sender.FirstName + " " + m.Sender.LastName,
                    MessageText = m.MessageText,
                    SentAt = m.SentAt,
                    IsRead = m.IsRead,
                    ReadAt = m.ReadAt,
                    IsFromRestaurant = m.SenderId != conversation.UserId
                })
                .ToListAsync();

            return messages;
        }

        public async Task<ChatMessageResponse> SendMessageAsync(int conversationId, int callerUserId, string messageText)
        {
            if (string.IsNullOrWhiteSpace(messageText))
                throw new ArgumentException("MessageText is required.", nameof(messageText));

            var conversation = await GetConversationForCallerAsync(conversationId, callerUserId);

            var msg = new ChatMessage
            {
                ConversationId = conversationId,
                SenderId = callerUserId,
                MessageText = messageText.Trim(),
                SentAt = DateTime.UtcNow,
                IsRead = false,
                ReadAt = null
            };

            _context.ChatMessages.Add(msg);

            // Keep conversation's LastMessageAt in sync (used for sorting lists)
            conversation.LastMessageAt = msg.SentAt;
            if (string.IsNullOrWhiteSpace(conversation.Status))
                conversation.Status = "Active";

            await _context.SaveChangesAsync();

            // Reload sender names for response (avoids tracking issues)
            var sender = await _context.Users.AsNoTracking().FirstAsync(u => u.Id == callerUserId);

            return new ChatMessageResponse
            {
                Id = msg.Id,
                ConversationId = msg.ConversationId,
                SenderId = msg.SenderId,
                SenderName = sender.FirstName + " " + sender.LastName,
                MessageText = msg.MessageText,
                SentAt = msg.SentAt,
                IsRead = msg.IsRead,
                ReadAt = msg.ReadAt,
                IsFromRestaurant = callerUserId != conversation.UserId
            };
        }

        public async Task<ChatMessageResponse> SendFirstMessageAsync(int restaurantId, int callerUserId, string messageText)
        {
            if (string.IsNullOrWhiteSpace(messageText))
                throw new ArgumentException("MessageText is required.", nameof(messageText));

            var restaurant = await _context.Restaurants
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.Id == restaurantId);

            if (restaurant == null)
                throw new KeyNotFoundException("Restaurant not found.");

            // Check if conversation already exists
            var existing = await _context.ChatConversations
                .FirstOrDefaultAsync(c => c.RestaurantId == restaurantId && c.UserId == callerUserId);

            ChatConversation conversation;
            if (existing == null)
            {
                // Create new conversation
                conversation = new ChatConversation
                {
                    RestaurantId = restaurantId,
                    UserId = callerUserId,
                    StartedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow,
                    Status = "Active"
                };
                _context.ChatConversations.Add(conversation);
                await _context.SaveChangesAsync(); // Save to get the ID
            }
            else
            {
                conversation = existing;
            }

            // Send the message
            var msg = new ChatMessage
            {
                ConversationId = conversation.Id,
                SenderId = callerUserId,
                MessageText = messageText.Trim(),
                SentAt = DateTime.UtcNow,
                IsRead = false,
                ReadAt = null
            };

            _context.ChatMessages.Add(msg);
            conversation.LastMessageAt = msg.SentAt;
            conversation.Status = "Active";

            await _context.SaveChangesAsync();

            // Reload sender names for response
            var sender = await _context.Users.AsNoTracking().FirstAsync(u => u.Id == callerUserId);

            return new ChatMessageResponse
            {
                Id = msg.Id,
                ConversationId = msg.ConversationId,
                SenderId = msg.SenderId,
                SenderName = sender.FirstName + " " + sender.LastName,
                MessageText = msg.MessageText,
                SentAt = msg.SentAt,
                IsRead = msg.IsRead,
                ReadAt = msg.ReadAt,
                IsFromRestaurant = false // First message is always from customer
            };
        }

        public async Task<int> MarkConversationReadAsync(int conversationId, int callerUserId)
        {
            await GetConversationForCallerAsync(conversationId, callerUserId);

            var now = DateTime.UtcNow;

            // Mark all messages not sent by caller as read.
            var unread = await _context.ChatMessages
                .Where(m => m.ConversationId == conversationId && !m.IsRead && m.SenderId != callerUserId)
                .ToListAsync();

            foreach (var m in unread)
            {
                m.IsRead = true;
                m.ReadAt = now;
            }

            if (unread.Count == 0)
                return 0;

            await _context.SaveChangesAsync();
            return unread.Count;
        }

        public async Task DeleteConversationAsync(int conversationId, int callerUserId)
        {
            var conversation = await GetConversationForCallerAsync(conversationId, callerUserId);

            // Delete all messages (cascade will handle this, but we can be explicit)
            var messages = await _context.ChatMessages
                .Where(m => m.ConversationId == conversationId)
                .ToListAsync();

            _context.ChatMessages.RemoveRange(messages);

            // Delete the conversation
            _context.ChatConversations.Remove(conversation);

            await _context.SaveChangesAsync();
        }

        private async Task<ChatConversation> GetConversationForCallerAsync(int conversationId, int callerUserId)
        {
            var conversation = await _context.ChatConversations
                .Include(c => c.Restaurant)
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == conversationId);

            if (conversation == null)
                throw new KeyNotFoundException("Conversation not found.");

            var isCustomer = conversation.UserId == callerUserId;
            var isOwner = conversation.Restaurant.OwnerId == callerUserId;

            if (!isCustomer && !isOwner)
                throw new UnauthorizedAccessException("You do not have access to this conversation.");

            return conversation;
        }

        private async Task<ChatConversationResponse> MapConversationForCallerAsync(int conversationId, int callerUserId)
        {
            var convo = await _context.ChatConversations
                .AsNoTracking()
                .Where(c => c.Id == conversationId)
                .Select(c => new ChatConversationResponse
                {
                    Id = c.Id,
                    UserId = c.UserId,
                    UserName = c.User.FirstName + " " + c.User.LastName,
                    RestaurantId = c.RestaurantId,
                    RestaurantName = c.Restaurant.Name,
                    StartedAt = c.StartedAt,
                    LastMessageAt = c.LastMessageAt,
                    Status = c.Status,
                    LastMessageText = c.Messages
                        .OrderByDescending(m => m.SentAt)
                        .Select(m => m.MessageText)
                        .FirstOrDefault(),
                    UnreadCount = c.Messages.Count(m => !m.IsRead && m.SenderId != callerUserId)
                })
                .FirstOrDefaultAsync();

            if (convo == null)
                throw new KeyNotFoundException("Conversation not found.");

            return convo;
        }
    }
}

