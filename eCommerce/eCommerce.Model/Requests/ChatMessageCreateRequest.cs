using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ChatMessageCreateRequest
    {
        [Required(ErrorMessage = "Message is required.")]
        [MaxLength(2000, ErrorMessage = "Message must not exceed 2000 characters.")]
        public string MessageText { get; set; } = string.Empty;
    }
}

