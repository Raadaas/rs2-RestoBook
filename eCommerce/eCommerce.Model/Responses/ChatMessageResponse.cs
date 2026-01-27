using System;

namespace eCommerce.Model.Responses
{
    public class ChatMessageResponse
    {
        public int Id { get; set; }

        public int ConversationId { get; set; }

        public int SenderId { get; set; }

        public string? SenderName { get; set; }

        public string MessageText { get; set; } = string.Empty;

        public DateTime SentAt { get; set; }

        public bool IsRead { get; set; }

        public DateTime? ReadAt { get; set; }

        /// <summary>
        /// True when the message is sent by the restaurant side (owner/staff),
        /// false when it's sent by the customer user that opened the conversation.
        /// </summary>
        public bool IsFromRestaurant { get; set; }
    }
}

