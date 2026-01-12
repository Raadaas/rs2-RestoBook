namespace eCommerce.Model.SearchObjects
{
    public class MenuItemSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? Name { get; set; }
        public MenuCategory? Category { get; set; }
        public bool? IsAvailable { get; set; }
    }
}

