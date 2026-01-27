namespace eCommerce.Model.SearchObjects
{
    public class ChatMessageSearchObject : BaseSearchObject
    {
        public int ConversationId { get; set; }

        /// <summary>
        /// If provided, returns only messages with Id greater than AfterId.
        /// Useful for polling new messages.
        /// </summary>
        public int? AfterId { get; set; }
    }
}

