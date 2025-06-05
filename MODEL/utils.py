from PIL import Image
import numpy as np
import torchvision.transforms as transforms
from numpy import ndarray
import torch
import torch.nn as nn
import json
import torch.nn.functional as F

with open("mapping.json", "r") as f:
    disease_name = json.load(f)

with open("index_mapping.json", "r") as f:
    disease_index = json.load(f)

all_labels = [label for sublist in disease_name.values() for label in sublist]


# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..
def resize_img(img_path: str) -> ndarray:
    image = Image.open(img_path).convert("RGB")

    # Resize to 256x256 and convert to tensor
    transform = transforms.Compose([
        transforms.Resize((256, 256)),  # <- Resize here
        transforms.ToTensor(),  # Converts to [0, 1] range and CHW format
    ])

    # Apply transform
    tensor = transform(image).unsqueeze(0).numpy().astype(np.float32)
    return tensor


# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

def resize_img_torch(img_path: str) -> ndarray:
    image = Image.open(img_path).convert("RGB")

    # Resize to 256x256 and convert to tensor
    transform = transforms.Compose([
        transforms.Resize((256, 256)),  # <- Resize here
        transforms.ToTensor(),  # Converts to [0, 1] range and CHW format
    ])

    # Apply transform
    tensor = transform(image).unsqueeze(0).to(dtype=torch.float32)
    return tensor


# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..

def accuracy(outputs, labels):
    _, preds = torch.max(outputs, dim=1)
    return torch.tensor(torch.sum(preds == labels).item() / len(preds))


def to_device(data, device):
    """Move tensor(s) to a chosen device"""
    if isinstance(data, (list, tuple)):
        return [to_device(x, device) for x in data]
    return data.to(device, non_blocking=True)


@torch.no_grad()
def evaluate(model, val_loader):
    model.eval()
    outputs = [model.validation_step(batch) for batch in val_loader]
    return model.validation_epoch_end(outputs)


def get_lr(optimizer):
    for param_group in optimizer.param_groups:
        return param_group['lr']


def fit_OneCycle(epochs, max_lr, model, train_loader, val_loader, weight_decay=0,
                 grad_clip=None, opt_func=torch.optim.SGD):
    torch.cuda.empty_cache()
    history = []  # For collecting the results

    optimizer = opt_func(model.parameters(), max_lr, weight_decay=weight_decay)
    # scheduler for one cycle learniing rate
    # Sets the learning rate of each parameter group according to the 1cycle learning rate policy.
    # The 1cycle policy anneals the learning rate from an initial learning rate to some
    # maximum learning rate and then from that maximum learning rate to some minimum learning rate
    # much lower than the initial learning rate.
    sched = torch.optim.lr_scheduler.OneCycleLR(optimizer, max_lr,
                                                epochs=epochs, steps_per_epoch=len(train_loader))

    for epoch in range(epochs):
        # Training
        model.train()
        train_losses = []
        lrs = []
        for batch in train_loader:
            loss = model.training_step(batch)
            train_losses.append(loss)
            loss.backward()

            # gradient clipping
            # Clip the gradients of an iterable of parameters at specified value.
            # All from pytorch documantation.
            if grad_clip:
                nn.utils.clip_grad_value_(model.parameters(), grad_clip)

            optimizer.step()
            optimizer.zero_grad()

            # recording and updating learning rates
            lrs.append(get_lr(optimizer))
            sched.step()
            # validation

        result = evaluate(model, val_loader)
        result['train_loss'] = torch.stack(train_losses).mean().item()
        result['lrs'] = lrs
        model.epoch_end(epoch, result)
        history.append(result)

    return history


def ODIN(predict_tensor, T=10000, epsilon=0.0014, delta=0.1):
    pass

def ODIN_tune():
    pass

# ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- .. ... . ....- .- ..
def handle_output(predict_tensor: ndarray, fruit: str = None) -> dict:
    """

    :param predict_tensor:
    :param fruit:
    :return: dictionary: {
    predicted_disease: (name, probability),
    probability: {other_1: probability,
                other_2:probability), …}
    }
    """
    chosen_fruit = predict_tensor
    this_fruit = all_labels
    if fruit is not None:
        chosen_fruit = predict_tensor[:, disease_index[fruit]]
        this_fruit = disease_name[fruit]

    fruit_predicted_prob = nn.Softmax(dim=-1)(torch.tensor(chosen_fruit))
    out = {'predicted_disease': (this_fruit[torch.argmax(fruit_predicted_prob)],
                                 (torch.max(fruit_predicted_prob) * 100).tolist()),
           'prob': dict(zip(this_fruit, (fruit_predicted_prob[0] * 100).tolist()))}

    return out

# def handle_output(predict_tensor: ndarray, fruit: str = None) -> dict:
#     if isinstance(predict_tensor, ndarray):
#         predict_tensor = torch.tensor(predict_tensor)
#
#     softmax = nn.Softmax(dim=-1)
#     probs = softmax(predict_tensor)
#     if fruit is not None:
#         logits = probs[:, disease_index[fruit]]
#         class_names = disease_name[fruit]
#     else:
#         logits = probs
#         class_names = all_labels
#
#     max_prob = torch.max(logits).item()
#     is_leaf = max_prob >= 0.8
#
#     predicted_class = class_names[torch.argmax(logits).item()]
#     prob_dict = dict(zip(class_names, (probs[0] * 100).tolist()))
#
#     return {
#         'predicted_disease': (predicted_class, max_prob * 100),
#         'prob': prob_dict,
#         'is_leaf': is_leaf
#     }
