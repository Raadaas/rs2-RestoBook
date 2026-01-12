using System;

namespace eCommerce.Model
{
    [Flags]
    public enum Allergen
    {
        None = 0,
        Gluten = 1,
        Crustaceans = 2,
        Eggs = 4,
        Fish = 8,
        Peanuts = 16,
        Soybeans = 32,
        Milk = 64,
        Nuts = 128,
        Celery = 256,
        Mustard = 512,
        Sesame = 1024,
        Sulfites = 2048,
        Lupin = 4096,
        Molluscs = 8192
    }
}

