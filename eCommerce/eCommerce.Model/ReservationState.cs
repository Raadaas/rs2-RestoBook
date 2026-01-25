namespace eCommerce.Model
{
    /// <summary>
    /// Represents the state of a reservation in the system.
    /// </summary>
    public enum ReservationState
    {
        /// <summary>
        /// Reservation has been requested but not yet confirmed.
        /// </summary>
        Requested = 0,

        /// <summary>
        /// Reservation has been confirmed by the restaurant.
        /// </summary>
        Confirmed = 1,

        /// <summary>
        /// Reservation has been completed (dining experience finished).
        /// </summary>
        Completed = 2,

        /// <summary>
        /// Reservation has been cancelled.
        /// </summary>
        Cancelled = 3,

        /// <summary>
        /// Reservation was requested but not confirmed, and its EndTime has passed.
        /// This state is automatically set by the system.
        /// </summary>
        Expired = 4
    }
}
