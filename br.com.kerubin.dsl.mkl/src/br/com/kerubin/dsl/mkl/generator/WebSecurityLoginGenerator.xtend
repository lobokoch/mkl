package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityLoginGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateLogin
	}
	
	def generateLogin(String securityPath) {
		val loginComponentName = securityPath + 'login/login.component'
		loginComponentName.generateLoginCSS
		loginComponentName.generateLoginHTML
		loginComponentName.generateLoginTS
	}
	
	def generateLoginTS(String loginComponentName) {
		val fileName = loginComponentName + '.ts'
		generateFile(fileName, generateLoginTSContent)
	}
	
	def CharSequence generateLoginTSContent() {
		'''
		import { Component, OnInit } from '@angular/core';
		import { Router } from '@angular/router';
		import { AuthService } from '../auth.service';
		import { MessageHandlerService } from 'src/app/core/message-handler.service';
		
		@Component({
		  selector: 'app-login',
		  templateUrl: './login.component.html',
		  styleUrls: ['./login.component.css']
		})
		export class LoginComponent implements OnInit {
		
		  constructor(
		    private auth: AuthService,
		    private messageHandler: MessageHandlerService,
		    private router: Router
		    ) { }
		
		  ngOnInit() {
		  }
		
		  login(username: string, password: string) {
		    this.auth.login(username, password)
		    .then(() => {
		      const tenant = this.auth.tenant;
		      if (tenant) {
		        this.router.navigate(['/mainmenu']);
		      } else {
		        this.router.navigate(['/confignewaccount']);
		      }
		    })
		    .catch (error => {
		      this.messageHandler.showError(error);
		    });
		  }
		
		}
		'''
	}
	
	def generateLoginHTML(String loginComponentName) {
		val fileName = loginComponentName + '.html'
		generateFile(fileName, generateLoginHTMLContent)
	}
	
	def CharSequence generateLoginHTMLContent() {
		'''
		<section>
		  <article>
		    <!--{{ auth.jwtPayload | json }}-->
		
		    <p-card [style]="{width: '360px', height: '350px'}" styleClass="ui-card-shadow">
		      <form #loginForm="ngForm">
		        <div class="ui-g ui-fluid">
		
		          <div class="ui-g-12">
		            <div class="kb-login-title">Acessar o Kerubin</div>
		          </div>
		
		          <div class="ui-g-12">
		            <div class="ui-inputgroup">
		              <span class="ui-inputgroup-addon"><i class="pi pi-user"></i></span>
		              <input pInputText type="email" name="username" placeholder="Seu e-mail" ngModel required #username>
		            </div>
		          </div>
		
		          <div class="ui-g-12">
		            <div class="ui-inputgroup">
		              <span class="ui-inputgroup-addon"><i class="pi pi-key"></i></span>
		              <input pInputText type="password" name="password" placeholder="Sua senha" ngModel required #password>
		            </div>
		          </div>
		
		          <div class="ui-g-12">
		            <button pButton style="font-weight: bold; border: 1px solid black; height: 150%" type="submit"
		              label="Entrar" (click)="login(username.value, password.value); password.value = '';">
		            </button>
		          </div>
		
		          <div style="margin-top: 20px" class="ui-g-12">
		            <div class="ui-g-12 ui-fluid ui-md-6">
		              <a routerLink="/newaccount" pButton style="font-weight: bold; border: 1px solid darkgreen"
		                class="ui-button-success" label="Criar uma conta"></a>
		            </div>
		
		            <div class="ui-g-12 ui-fluid ui-md-6">
		              <a routerLink="/mainmenu" pButton style="border: 1px solid silver" class="ui-button-secondary"
		                label="Esqueci a senha"></a>
		            </div>
		          </div>
		
		        </div>
		      </form>
		    </p-card>
		
		  </article>
		</section>
		'''
	}
	
	def generateLoginCSS(String loginComponentName) {
		val fileName = loginComponentName + '.css'
		generateFile(fileName, generateLoginCSSContent)
	}
	
	def CharSequence generateLoginCSSContent() {
		'''		
		section{
		  position: absolute;
		  top: 0;
		  left: 0;
		  width: 100%;
		  height: 100%;
		}
		
		article{
		  margin: 0 auto;
		  align-items: center;
		  display: flex;
		  justify-content: center;
		  height: 80%;
		  width: 100%;
		}
		
		.kb-login-title {
		  font-size: 2em;
		  font-weight: bold;
		}
		'''
	}
	
}