using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Table
    {
        [Key]
        public int Id { get; set; }
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        [Required]
        [MaxLength(20)]
        public string TableNumber { get; set; } = string.Empty;
        
        public int Capacity { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionX { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionY { get; set; }
        
        [MaxLength(50)]
        public string? TableType { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        // Navigation properties
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}

