import warnings
import torch.nn.functional as F
from torchvision.datasets import ImageFolder
from torch.utils.data import DataLoader
from utils import *

# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

warnings.filterwarnings('ignore')
batch_size = 36

data_s = ImageFolder('train', transform=transforms.ToTensor())

# Define split sizes
train_size = int(0.8 * len(data_s))
test_size = len(data_s) - train_size

# Randomly split
train, test = torch.utils.data.random_split(data_s, [train_size, test_size])
train_dataloader = DataLoader(train, batch_size, shuffle=True, num_workers=2, pin_memory=True)
test_dataloader = DataLoader(test, batch_size, num_workers=2, pin_memory=True)

# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

device = 'cuda' if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu"


class DeviceDataLoader:
    """Wrap a dataloader to move data to a device"""

    def __init__(self, dataloader, device):
        self.dataloader = dataloader
        self.device = device

    def __iter__(self):
        """Yield a batch of data after moving it to a device"""
        for b in self.dataloader:
            yield to_device(b, self.device)

    def __len__(self):
        """Number of batches"""
        return len(self.dataloader)


train_dataloader = DeviceDataLoader(train_dataloader, device)
valid_dataloader = DeviceDataLoader(test_dataloader, device)


# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

class ImageClassificationBase(nn.Module):

    def training_step(self, batch):
        images, labels = batch
        out = self(images)  # Generate predictions
        loss = F.cross_entropy(out, labels)  # Calculate loss
        return loss

    def validation_step(self, batch):
        images, labels = batch
        out = self(images)  # Generate predictions
        loss = F.cross_entropy(out, labels)  # Calculate loss
        acc = accuracy(out, labels)  # Calculate accuracy
        return {'val_loss': loss.detach(), 'val_acc': acc}

    def validation_epoch_end(self, outputs):
        batch_losses = [x['val_loss'] for x in outputs]
        epoch_loss = torch.stack(batch_losses).mean()  # Combine losses
        batch_accs = [x['val_acc'] for x in outputs]
        epoch_acc = torch.stack(batch_accs).mean()  # Combine accuracies
        return {'val_loss': epoch_loss.item(), 'val_acc': epoch_acc.item()}

    def epoch_end(self, epoch, result):
        print("Epoch [{}], train_loss: {:.4f}, val_loss: {:.4f}, val_acc: {:.4f}".format(
            epoch, result['train_loss'], result['val_loss'], result['val_acc']))


def ConvBlock(in_channels, out_channels, pool=False):
    layers = [nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1),
              nn.BatchNorm2d(out_channels),
              nn.ReLU(inplace=True)]
    if pool:
        layers.append(nn.MaxPool2d(4))
    return nn.Sequential(*layers)


class CNN_NeuralNet(ImageClassificationBase):
    def __init__(self, in_channels, num_diseases):
        super().__init__()

        self.conv1 = ConvBlock(in_channels, 64)
        self.conv2 = ConvBlock(64, 128, pool=True)
        self.res1 = nn.Sequential(ConvBlock(128, 128), ConvBlock(128, 128))

        self.conv3 = ConvBlock(128, 256, pool=True)
        self.conv4 = ConvBlock(256, 512, pool=True)
        # self.conv5 = ConvBlock(256, 256, pool=True)
        # self.conv6 = ConvBlock(256, 512, pool=True)
        # self.conv7 = ConvBlock(512, 512, pool=True)

        self.res2 = nn.Sequential(ConvBlock(512, 512), ConvBlock(512, 512))
        self.classifier = nn.Sequential(nn.MaxPool2d(4),
                                        nn.Flatten(),
                                        nn.Linear(512, num_diseases))

    def forward(self, x):  # x is the loaded batch
        out = self.conv1(x)
        out = self.conv2(out)
        out = self.res1(out) + out
        out = self.conv3(out)
        out = self.conv4(out)
        # out = self.conv5(out)
        # out = self.conv6(out)
        # out = self.conv7(out)
        out = self.res2(out) + out
        out = self.classifier(out)
        return out


model = CNN_NeuralNet(3, 66)  # make sure this class is defined
state_dict = torch.load('model_weights.pth', map_location=torch.device('cpu'))
model.load_state_dict(state_dict)
model.eval()

# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

num_epoch = 5
lr_rate = 0.01
grad_clip = 0.15
weight_decay = 1e-4
optims = torch.optim.AdamW

history = [evaluate(model, valid_dataloader)]
history += fit_OneCycle(num_epoch, lr_rate, model, train_dataloader, valid_dataloader,
                        grad_clip=grad_clip,
                        weight_decay=weight_decay,
                        opt_func=optims)

# torch.save(model.state_dict(), 'model_weights.pth')

# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

dummy_input = torch.randn(1, 3, 256, 256).numpy()  # batch_size=1, channels=3, height=224, width=224
torch.onnx.export(
    model,  # your model
    dummy_input,  # a sample input
    "cnn_model.onnx",  # where to save
    input_names=['input'],  # name for input
    output_names=['output'],  # name for output
    dynamic_axes={  # make it flexible for batch size
        'input': {0: 'batch_size'},
        'output': {0: 'batch_size'}
    },
    opset_version=11  # ONNX opset version (11 is widely supported)
)
