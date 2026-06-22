import torch.nn as nn
import torchvision.models as models


class FatigueModel(nn.Module):
    def __init__(self, num_classes: int = 4, dropout: float = 0.5):
        super().__init__()
        self.backbone = models.efficientnet_b0(weights=None)
        inf = self.backbone.classifier[1].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(inf, 512),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(512),
            nn.Dropout(dropout / 2),
            nn.Linear(512, 256),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(256),
            nn.Linear(256, num_classes),
        )

    def forward(self, x):
        return self.backbone(x)
