package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebCoreMessageHandlerServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebCoreDir
		path.generateMessageHandlerService
	}
	
	def generateMessageHandlerService(String securityPath) {
		val name = securityPath + 'message-handler.service'
		name.generateMessageHandlerServiceTS
	}
	
	def generateMessageHandlerServiceTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateMessageHandlerServiceTSContent)
	}
	
	def CharSequence generateMessageHandlerServiceTSContent() {
		'''
		import { UserNotAuthenticatedError } from './exceptions';
		import { Injectable } from '@angular/core';
		import { MessageService } from 'primeng/api';
		import { HttpErrorResponse } from '@angular/common/http';
		import { Router } from '@angular/router';
		
		@Injectable({
		  providedIn: 'root'
		})
		export class MessageHandlerService {
		
		  constructor(
		    private messageService: MessageService,
		    private router: Router
		    ) { }
		
		  showError(errorResponse: any) {
		
		    if (errorResponse instanceof UserNotAuthenticatedError) {
		      return;
		      // Esse erro já foi tratado na rotina http-client-token.ts
		      // message = 'Sua sessão expirou! Refaça login.';
		      // this.router.navigate(['/login']);
		    }
		
		    let message = 'Ocorreu um erro ao processar a operação. Tente novamente mais tarde.';
		
		    let errorIsResponse = false;
		    errorIsResponse = errorResponse instanceof HttpErrorResponse;
		    if (!errorIsResponse) {
		      errorIsResponse = errorResponse.constructor.name === 'HttpErrorResponse';
		    }
		
		    if (typeof errorResponse === 'string') {
		      message = errorResponse;
		    } else if (errorIsResponse && errorResponse.status >= 400 && errorResponse.status <= 499) {
		      try {
		
		        if (errorResponse.error) {
		          if (errorResponse.error.error_description) {
		            message = errorResponse.error.error_description;
		          } else if (errorResponse.error.message) {
		            message = errorResponse.error.message;
		          } else {
		            message = 'Ocorreu um erro. Tente novamente em alguns instantes';
		          }
		
		        }
		
		      } catch (e) {
		        console.log('Ocorreu um erro:' + e);
		      }
		    }
		
		    this.messageService.add({severity: 'error', summary: 'Erro', detail: message});
		    console.log('Ocorreu um erro:' + errorResponse);
		  }
		
		  showSuccess(message: string) {
		    this.messageService.add({severity: 'success', summary: 'Successo', detail: message});
		  }
		
		}

		'''
	}
	
}