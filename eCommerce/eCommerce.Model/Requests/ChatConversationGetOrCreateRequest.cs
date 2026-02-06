using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ChatConversationGetOrCreateRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
    }
}

