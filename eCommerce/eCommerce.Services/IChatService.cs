using eCommerce.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface IChatService
    {
        Task<ChatConversationResponse?> GetConversationAsync(int restaurantId, int customerUserId);

        /// <summary>
        /// Conversations for the customer side (mobile app). Uses caller as customer.
        /// </summary>
        Task<List<ChatConversationResponse>> GetMyConversationsAsync(int customerUserId);

        /// <summary>
        /// Conversations for a specific restaurant (desktop owner view). Uses caller as restaurant owner.
        /// </summary>
        Task<List<ChatConversationResponse>> GetRestaurantConversationsAsync(int restaurantId, int ownerUserId);

        /// <summary>
        /// Gets messages for a conversation. If afterId is set, returns only messages with Id > afterId.
        /// Otherwise returns last pageSize messages (page=0 is the newest page).
        /// </summary>
        Task<List<ChatMessageResponse>> GetMessagesAsync(int conversationId, int callerUserId, int? afterId = null, int page = 0, int pageSize = 50);

        Task<ChatMessageResponse> SendMessageAsync(int conversationId, int callerUserId, string messageText);
        
        /// <summary>
        /// Sends the first message to a restaurant, creating the conversation if it doesn't exist.
        /// </summary>
        Task<ChatMessageResponse> SendFirstMessageAsync(int restaurantId, int callerUserId, string messageText);

        /// <summary>
        /// Marks all messages sent by the other side as read.
        /// Returns number of updated rows.
        /// </summary>
        Task<int> MarkConversationReadAsync(int conversationId, int callerUserId);

        /// <summary>
        /// Deletes a conversation and all its messages. Only the customer or restaurant owner can delete.
        /// </summary>
        Task DeleteConversationAsync(int conversationId, int callerUserId);
    }
}

