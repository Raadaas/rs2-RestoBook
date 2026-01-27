using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ChatMessageCreateRequest
    {
        [Required]
        [MaxLength(2000)]
        public string MessageText { get; set; } = string.Empty;
    }
}

