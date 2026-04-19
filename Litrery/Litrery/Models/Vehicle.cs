namespace Litrery.Models;

public class Vehicle
{
    public string VehicleIdentificationNumber { get; set; } = string.Empty;
    public string EngineNumber { get; set; } = string.Empty;
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string Year { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string RegistrationNumber { get; set; } = string.Empty;
    public int Odometer { get; set; }
}
