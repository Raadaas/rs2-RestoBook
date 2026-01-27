namespace eCommerce.Model.SearchObjects
{
    public class ChatConversationSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public int? UserId { get; set; }
        public bool? UnreadOnly { get; set; }
    }
}

