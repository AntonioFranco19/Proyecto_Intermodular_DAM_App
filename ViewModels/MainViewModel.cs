using CommunityToolkit.Mvvm.ComponentModel;

namespace Proyecto_Intermodular_APP.ViewModels;

public partial class MainViewModel : ViewModelBase
{
    [ObservableProperty]
    public partial string Greeting { get; set; } = "Welcome to Avalonia!";
}
