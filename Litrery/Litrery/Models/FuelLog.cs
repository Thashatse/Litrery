using Newtonsoft.Json;

namespace Litrery.Models;

public class FuelLog
{
    [JsonProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    public DateTime Date { get; set; }

    public double? KilometresDriven { get; set; }
    
    public double? Litres { get; set; } 

    public double? CostZar { get; set; } 

    public double? LPer100Km { get; set; }

    public int? BarsRemaining { get; set; } 

    public string? Notes { get; set; }
}