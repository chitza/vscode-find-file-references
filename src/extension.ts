"use strict";

import * as vscode from "vscode";
import path from "path";

export function activate(context: vscode.ExtensionContext) {
  const disposable = vscode.commands.registerCommand(`vscode-find-file-references.findFileReferences`, (e: vscode.Uri) => {
    let filename = "";
    if (e) {
      filename = path.basename(e.fsPath);
    } else {
      const uri = vscode.window.activeTextEditor?.document.uri;
      if (!uri) {
        vscode.window.showErrorMessage("No active text editor found.");
        return;
      }
      filename = path.basename(uri.fsPath);
    }

    // call findInFiles command with the filename
    vscode.commands.executeCommand("workbench.action.findInFiles", {
      query: filename,
      // matchWholeWord: true
    });
  });

  context.subscriptions.push(disposable);
}

export function deactivate() {}
